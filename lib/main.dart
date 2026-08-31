import 'dart:async';

import 'package:dio/dio.dart';
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
  // above delegate to this immediately, and AuthController.login() (see
  // app/modules/auth/controllers/auth_controller.dart) writes through them
  // as soon as it runs.
  await Get.putAsync(() => SessionService().init(), permanent: true);

  await Get.putAsync(() => ConnectivityService().init(), permanent: true);

  // Restore a persisted login before the first frame - mirrors
  // docwellness-user's getUserData(). Without this the dietician was sent
  // to the login screen far more often than she should have been.
  await restoreSession();

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
  const bool enableFirebaseNotifications = true;

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

  // Initialize Socket Service
  await Get.putAsync(() => SocketService().init());

  await _initPostHog();
}

/// Restores the persisted session at cold start so a logged-in dietician
/// stays logged in across app launches - the same handling docwellness-user
/// does in getUserData(). Only forces a logout (clearing the session so
/// SplashView routes to AUTH) when there is genuinely no session, or the
/// backend explicitly rejects the refresh token. A network blip / timeout /
/// 5xx keeps the cached session and lets the app run (offline-tolerant),
/// rather than bouncing her to the login screen. `userId` (not part of the
/// JWT) is re-fetched from /auth/me every launch, which also self-heals a
/// flaky secure-storage read.
Future<void> restoreSession() async {
  final session = SessionService.to;
  final refreshToken = session.refreshToken;
  if ((session.token?.isEmpty ?? true) || (refreshToken?.isEmpty ?? true)) {
    await session.clear();
    return;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      // Kept short: this blocks the first frame, and offline should fall
      // through to "run with the cached session" fast, not hang on a splash.
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      // 4xx returns normally so we can tell "refresh token rejected" (log
      // out) apart from a thrown 5xx / network error (keep cached session).
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final expiresAt = int.tryParse(session.tokenExpiresAt ?? '');
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final needsRefresh = expiresAt == null || nowSeconds >= expiresAt - 30;

  if (needsRefresh) {
    try {
      final res = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final ok = res.statusCode == 200 &&
          res.data is Map &&
          res.data['success'] == true;
      if (ok) {
        final data = res.data['data'];
        await session.setSession(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: (data['expiresAt'] as num?)?.toInt() ?? 0,
        );
        token = data['accessToken'];
      } else {
        // Backend answered and said this refresh token is no good - a real
        // "please log in again".
        debugPrint('restoreSession: refresh rejected (${res.statusCode}) - logging out');
        await session.clear();
        return;
      }
    } catch (e) {
      // Timeout / DNS / 5xx / offline - says nothing about token validity.
      // Keep the cached session so she isn't logged out over a hiccup.
      debugPrint('restoreSession: refresh error, using cached token: $e');
    }
  }

  try {
    final me = await dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer ${session.token}'}),
    );
    if (me.statusCode == 200 && me.data is Map && me.data['success'] == true) {
      userId = me.data['data']['_id'];
    }
  } catch (e) {
    // 401/network/anything - don't touch userId; the getter already returns
    // whatever SessionService.init() hydrated from secure storage.
    debugPrint('restoreSession: /auth/me failed, using cached userId: $e');
  }
}

Future<void> _initPostHog() async {
  if (EnvService.posthogApiKey.isEmpty) return;
  final config = PostHogConfig(EnvService.posthogApiKey)
    ..host = EnvService.posthogHost;
  await Posthog().setup(config);
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
