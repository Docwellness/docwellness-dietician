import 'package:get/get.dart';

import '../controllers/exercises_controller.dart';

class ExercisesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExercisesController>(
      () => ExercisesController(),
    );
  }
}
