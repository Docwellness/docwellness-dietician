import 'dart:async';

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
import 'core/config/env_service.dart';
import 'core/session/session_service.dart';

/// Thin bridge over SessionService (see core/session/session_service.dart)
/// so every existing call site that reads/writes `token`/`userId` directly
/// keeps working unchanged, while the actual session data now lives in the
/// service's secure-storage-backed state instead of a bare in-memory
/// global that's lost on every app restart. SessionService must already be
/// registered (see _bootstrap's first line) before anything touches these.
String? get token => SessionService.to.token;
set token(String? value) => unawaited(SessionService.to.setToken(value));

String? get userId => SessionService.to.userId;
set userId(String? value) => unawaited(SessionService.to.setUserId(value));

const String apiBaseUrl = '${EnvService.apiHost}/api/dietician';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized() must be called for the first
  // time in the same zone runApp() ends up running in - SentryFlutter.init's
  // appRunner runs inside its own runZonedGuarded zone, so calling
  // ensureInitialized() here in main()'s outer zone (when Sentry is enabled)
  // caused a "Zone mismatch" assertion. Both branches now call it from
  // inside _bootstrap(), invoked directly in main()'s zone when Sentry is
  // off, or inside appRunner's zone when it's on.
  if (EnvService.sentryDsn.isEmpty) {
    await _bootstrap();
    runApp(MyApp());
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvService.sentryDsn;
        options.environment = EnvService.appEnv;
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

  // Registered before anything else - the token/userId getters/setters
  // above delegate to this immediately, including from deep inside
  // _autoLoginDietician() further down this same function.
  await Get.putAsync(() => SessionService().init(), permanent: true);

  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  if (EnvService.supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: EnvService.supabaseUrl,
      publishableKey: EnvService.supabasePublishableKey,
    );

    // The SDK auto-refreshes the access token in the background using the
    // refresh token, shortly before the current one expires (~1hr default
    // TTL) - but that refreshed token only lives inside the SDK's own
    // session state. SessionService/token above holds a copy taken once at
    // sign-in for attaching to backend API calls, and without this
    // listener that copy goes stale the moment the original token expires:
    // every backend call then starts failing with 401 "token invalid"
    // until the app is killed and relaunched, even though the user was
    // never actually signed out.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        token = session.accessToken;
      }
    });
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
  if (EnvService.posthogApiKey.isEmpty) return;
  final config = PostHogConfig(EnvService.posthogApiKey)
    ..host = EnvService.posthogHost;
  await Posthog().setup(config);
}

Future<void> _autoLoginDietician() async {
  if (EnvService.dieticianAutoLoginEmail.isEmpty ||
      EnvService.dieticianAutoLoginPassword.isEmpty) {
    return;
  }

  // A previous boot already signed in and SessionService restored that
  // session from secure storage above - trust it instead of re-authenticating
  // over the network on every single launch. Re-authenticating unconditionally
  // meant a transient network hiccup at boot (DNS not resolved yet, brief
  // Wi-Fi reconnect blip, etc.) hit the catch block below and nulled out an
  // otherwise-perfectly-valid token, silently breaking every screen's data
  // for the rest of the session until the next successful login.
  if ((token?.isNotEmpty ?? false) && (userId?.isNotEmpty ?? false)) {
    return;
  }

  // We only reach here with no persisted session, so retrying a few times
  // on transient failures (and leaving token/userId untouched in between)
  // is safe - there's nothing valid yet to accidentally wipe out.
  //
  // Backoff is deliberately a few seconds (not milliseconds): the observed
  // failure mode is the device's DNS resolver not being ready yet for the
  // very first outbound request right after cold boot (especially right
  // after a network interface change, e.g. Wi-Fi reconnecting) - it
  // consistently fails for a couple of seconds and then works, so a short
  // retry loop clears it without the user ever noticing.
  const maxAttempts = 4;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: EnvService.dieticianAutoLoginEmail,
        password: EnvService.dieticianAutoLoginPassword,
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
        // AI_EXECUTION_PLAN.md Phase 8, P8-04 - no PHI: no properties, same
        // shape as the user app's login_success.
        await Posthog().capture(eventName: 'login_success');
      } else {
        debugPrint(
          'Dietician auto-login: /auth/me failed (${response?.statusCode})',
        );
        token = null;
      }
      return;
    } catch (e) {
      debugPrint('Dietician auto-login attempt $attempt/$maxAttempts failed: $e');
      if (attempt == maxAttempts) {
        break;
      }
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }

  // Exhausted the boot-time retries - the device was likely fully offline,
  // not just slow to resolve DNS. Rather than leaving the app stuck with no
  // session until the next manual restart, retry once connectivity actually
  // comes back (same reconnect signal screens use to refetch stale data).
  if (Get.isRegistered<ConnectivityService>()) {
    final connectivity = Get.find<ConnectivityService>();
    late final VoidCallback retry;
    retry = () {
      connectivity.unregister(retry);
      unawaited(_autoLoginDietician());
    };
    connectivity.registerOnReconnected(retry);
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
