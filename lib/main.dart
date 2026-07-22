import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/utils/theme/app_date_picker_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/services/connectivity_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/socket_service.dart';
import 'app/utils/functions/dio_function.dart';
import 'dev_credentials.dart';

String? token;
String? userId;

/// Backend base URL. Override at build time with:
///   flutter build web --dart-define=API_BASE_URL=https://api-dev.example.com
const String _apiHost = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);
const String apiBaseUrl = '$_apiHost/api/dietician';

// Publishable (anon) key - safe to commit, same as docwellness-user's
// scripts/run-dev.ps1 (it only allows the actions RLS policies permit, not
// reading arbitrary data - never the *service role* key). Defaulted here
// (rather than left empty like the optional Sentry/PostHog defines below)
// because auto-login below can't function at all without Supabase actually
// being initialized - this project's run-dev.ps1 was missing both of these
// dart-defines entirely, unlike docwellness-user's equivalent script.
const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ovflhhhtwrjthnyrnaoo.supabase.co',
);
const String _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_FmRYCR40VTVGDsHxK7Z9jQ_67UZ-t-o',
);

// TEMPORARY, until a real login screen exists: since there's only one
// dietician account, auto-sign-in as them at boot rather than build a login
// UI for a single user. Credentials come from either a --dart-define at
// launch time, or (falling back, for a plain `flutter run` with no defines)
// lib/dev_credentials.dart - a gitignored, uncommitted local file (see
// dev_credentials.example.dart for the template) so the real password never
// enters git history or the compiled app's committed source. Auto-login is
// a no-op unless both end up non-empty. Replace with a real login screen
// once there's more than one dietician.
const String _autoLoginEmail = String.fromEnvironment(
  'DIETICIAN_AUTO_LOGIN_EMAIL',
  defaultValue: kDevDieticianEmail,
);
const String _autoLoginPassword = String.fromEnvironment(
  'DIETICIAN_AUTO_LOGIN_PASSWORD',
  defaultValue: kDevDieticianPassword,
);

// Sentry/PostHog are only enabled once a real DSN/API key is supplied via
// --dart-define at build time; empty defaults keep both no-ops so local runs
// without those defines behave exactly as before.
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);
const String _appEnv = String.fromEnvironment(
  'ENV',
  defaultValue: 'development',
);
const String _posthogApiKey = String.fromEnvironment(
  'POSTHOG_API_KEY',
  defaultValue: '',
);
const String _posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized() must be called for the first
  // time in the same zone runApp() ends up running in - SentryFlutter.init's
  // appRunner runs inside its own runZonedGuarded zone, so calling
  // ensureInitialized() here in main()'s outer zone (when Sentry is enabled)
  // caused a "Zone mismatch" assertion. Both branches now call it from
  // inside _bootstrap(), invoked directly in main()'s zone when Sentry is
  // off, or inside appRunner's zone when it's on.
  if (_sentryDsn.isEmpty) {
    await _bootstrap();
    runApp(MyApp());
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.environment = _appEnv;
        options.tracesSampleRate = 0.0;
      },
      appRunner: () async {
        await _bootstrap();
        runApp(MyApp());
      },
    );
  }
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  if (_supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
  }

  // Toggle to enable/disable Firebase push notification wiring.
  const bool enableFirebaseNotifications = false;

  // Try to initialize Firebase; notification init is optional and controlled by flag.
  if (enableFirebaseNotifications) {
    try {
      await Firebase.initializeApp();
      await NotificationService().init();
    } catch (e) {
      debugPrint(
        'Firebase initialization failed (missing google-services.json?): $e',
      );
    }
  }

  await _autoLoginDietician();

  // Initialize Socket Service
  await Get.putAsync(() => SocketService().init());

  await _initPostHog();
}

Future<void> _initPostHog() async {
  if (_posthogApiKey.isEmpty) return;
  final config = PostHogConfig(_posthogApiKey)..host = _posthogHost;
  await Posthog().setup(config);
}

Future<void> _autoLoginDietician() async {
  if (_autoLoginEmail.isEmpty || _autoLoginPassword.isEmpty) return;

  try {
    final authRes = await Supabase.instance.client.auth.signInWithPassword(
      email: _autoLoginEmail,
      password: _autoLoginPassword,
    );
    final session = authRes.session;
    if (session == null) {
      debugPrint('Dietician auto-login: no session returned');
      return;
    }
    token = session.accessToken;

    final response = await ApiService().request(
      endPoint: '/auth/me',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response != null &&
        response.statusCode == 200 &&
        response.data['success'] == true) {
      userId = response.data['data']['_id'];
      debugPrint('🧪 Auto-logged in as dietician: userId=$userId');
    } else {
      debugPrint(
        'Dietician auto-login: /auth/me failed (${response?.statusCode})',
      );
      token = null;
    }
  } catch (e) {
    debugPrint('Dietician auto-login failed: $e');
    token = null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Application",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff851653),
          primary: const Color(0xff851653),
          onPrimary: Colors.white,
          surface: const Color(0xffFEF6FB),
        ),
        datePickerTheme: brandDatePickerTheme,
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xffFEF6FB),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
          contentTextStyle: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xff4D5761),
            height: 1.4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xff530630)),
        ),
      ),
      // Reserves space for the system's bottom navigation (3-button bar or
      // gesture-nav inset) on every single screen, not just ones with a
      // Scaffold.bottomNavigationBar - apps targeting Android 15+ render
      // edge-to-edge by default, so anything ending near the bottom of a
      // plain scrollable body (e.g. a form's submit button) was otherwise
      // getting drawn underneath the system nav bar. top: false since each
      // screen's own AppBar already accounts for the status bar correctly.
      builder: (context, child) =>
          SafeArea(top: false, child: child ?? const SizedBox.shrink()),
    );
  }
}
