import 'package:get/get.dart';

import '../controllers/finalize_step_controller.dart';
import '../controllers/generation_step_controller.dart';
import '../controllers/targets_step_controller.dart';
import '../controllers/timeline_step_controller.dart';
import '../controllers/wizard_controller.dart';

/// WizardController is instantiated eagerly (it needs the URL params passed
/// in at construction time, see app_pages.dart) - the 5 step controllers
/// are lazy (Get.lazyPut), only truly created when their step's view first
/// builds, same normal GetX behavior every other module here uses.
class WizardBinding extends Bindings {
  final WizardController wizardController;

  WizardBinding(this.wizardController);

  @override
  void dependencies() {
    Get.put<WizardController>(wizardController);
    Get.lazyPut<TargetsStepController>(() => TargetsStepController());
    Get.lazyPut<TimelineStepController>(() => TimelineStepController());
    Get.lazyPut<GenerationStepController>(() => GenerationStepController());
    Get.lazyPut<FinalizeStepController>(() => FinalizeStepController());
  }
}
