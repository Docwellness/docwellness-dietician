import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(),
      // Re-created if a route change (e.g. offAllNamed back to login) disposed
      // it - otherwise the login fields throw "used after being disposed".
      fenix: true,
    );
  }
}
