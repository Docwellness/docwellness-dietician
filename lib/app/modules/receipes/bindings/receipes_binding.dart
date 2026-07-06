import 'package:get/get.dart';

import '../controllers/receipes_controller.dart';

class ReceipesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceipesController>(
      () => ReceipesController(),
    );
  }
}
