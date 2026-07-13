import 'package:docwellnesdoc/app/modules/home/views/bottom_navi_bar.dart';
import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/notifications/bindings/notification_binding.dart';
import '../modules/notifications/views/notification_view.dart';
import '../modules/patients/bindings/patients_binding.dart';
import '../modules/patients/views/patient_profile_view.dart';
import '../modules/patients/views/patients_view.dart';
import '../modules/performance/bindings/performance_binding.dart';
import '../modules/performance/views/performance_view.dart';
import '../modules/receipes/bindings/receipes_binding.dart';
import '../modules/receipes/views/receipes_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => BottomNaviBar(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.CHAT,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: _Paths.PATIENTS,
      page: () => const PatientsView(),
      binding: PatientsBinding(),
    ),
    GetPage(
      name: _Paths.RECEIPES,
      page: () => const ReceipesView(),
      binding: ReceipesBinding(),
    ),
    GetPage(
      name: _Paths.PERFORMANCE,
      page: () => const PerformanceView(),
      binding: PerformanceBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATIONS,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: _Paths.PATIENT_PROFILE,
      // Reading patientId from Get.parameters (populated by the router from
      // the URL) rather than only a widget constructor arg means a full
      // browser refresh on this route can reconstruct the page instead of
      // crashing with no way to recover which patient was being viewed.
      page: () =>
          PatientProfileView(patientId: Get.parameters['patientId'] ?? ''),
    ),
  ];
}
