import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/utils/theme/app_date_picker_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/services/notification_service.dart';
import 'app/services/socket_service.dart';

String? token;
String? userId;

/// Backend base URL. Override at build time with:
///   flutter build web --dart-define=API_BASE_URL=https://api-dev.example.com
const String _apiHost = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000',
);
const String apiBaseUrl = '$_apiHost/api/dietician';

// Dev-only auto-login. Must stay false outside local development — there is
// no login screen in this app yet, so leaving this on would ship a real,
// long-lived auth token in every build, including production.
const bool testMode = false;
const String testDieticianId = '6a4b7eee2b490bb61892a756';
const String testDieticianToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNGI3ZWVlMmI0OTBiYjYxODkyYTc1NiIsImlhdCI6MTc4MzMzMjU5MCwiZXhwIjoxODE0ODY4NTkwfQ.I-lh9w8bXHXsxy6NOvHpWLqGyHyN99UNjN6axnqycug';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // For local development only: auto-login as the seeded local dietician
  // account (backend: mongodb://localhost:27017/docwellness) since there is
  // no login screen yet.
  if (testMode) {
    userId = testDieticianId;
    token = testDieticianToken;
    debugPrint('🧪 TEST MODE: userId=$userId');
  }

  // Initialize Socket Service
  await Get.putAsync(() => SocketService().init());

  runApp(MyApp());
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
    );
  }
}
