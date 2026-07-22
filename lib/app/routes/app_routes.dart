part of 'app_pages.dart';
// DO NOT EDIT. This is code generated via package:get_cli/get_cli.dart

abstract class Routes {
  Routes._();
  static const SPLASH = _Paths.SPLASH;
  static const HOME = _Paths.HOME;
  static const AUTH = _Paths.AUTH;
  static const CHAT = _Paths.CHAT;
  static const PATIENTS = _Paths.PATIENTS;
  static const RECEIPES = _Paths.RECEIPES;
  static const PERFORMANCE = _Paths.PERFORMANCE;
  static const NOTIFICATIONS = _Paths.NOTIFICATIONS;
  static const PATIENT_PROFILE = _Paths.PATIENT_PROFILE;
  static const SELECT_DIET_SHEET = _Paths.SELECT_DIET_SHEET;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH = '/splash';
  static const HOME = '/home';
  static const AUTH = '/auth';
  static const CHAT = '/chat';
  static const PATIENTS = '/patients';
  static const RECEIPES = '/receipes';
  static const PERFORMANCE = '/performance';
  static const NOTIFICATIONS = '/notifications';
  static const PATIENT_PROFILE = '/patient-profile/:patientId';
  static const SELECT_DIET_SHEET =
      '/select-diet-sheet/:patientId/:dietPlanId/:week';
}
