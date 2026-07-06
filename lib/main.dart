import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/routes/app_pages.dart';
import 'app/services/notification_service.dart';
import 'app/services/socket_service.dart';

String? token;
String? userId;
const String apiBaseUrl = 'http://65.20.81.44:5001/api/dietician';

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

  // Token valid until May 20, 2026 (30 days from Apr 20, 2026)

  token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5Mjk2MDFiMTJiZDlmODllZGI3ZTY5NyIsImlhdCI6MTc3NjY3NDM2MywiZXhwIjoxNzc5MjY2MzYzfQ.E2REMPHMqPD-wV3FuW-hZOD72JJmQkOglLq2bigZh08';

  // User ID for the dietician (extracted from token)
  userId = '6929601b12bd9f89edb7e697';

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
