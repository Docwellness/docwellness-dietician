import 'package:get/get.dart';

import '../models/wizard_week_models.dart';
import '../services/diet_plan_wizard_service.dart';
import 'wizard_controller.dart';

/// Step 5 (Finalize), v4.0 ('plan-item') mode - the sibling to
/// FinalizeStepController, used instead of it for a DietPlan whose
/// dataModel is 'plan-item' (see wizard_view.dart's routing). Portion
/// refinement already happened at Step 3 (refine_portions_step_controller.dart)
/// - this step is now purely the read-only "Sanity Check" detail view the
/// v4.0 spec describes: exact recipe name/ingredients/steps/supplements for
/// every item, then "Confirm & Activate" (which finalizes this week AND
/// activates the plan in one tap, matching the spec's single button).
class PlanItemFinalizeStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<WizardDayGroupV2> weekDays = <WizardDayGroupV2>[].obs;
  final RxBool activating = false.obs;

  String get patientId => wizard.patientId;
  String get dietPlanId => wizard.dietPlanId.value ?? '';
  int get week => wizard.targetWeek.value;

  @override
  void onInit() {
    super.onInit();
    if (dietPlanId.isNotEmpty) loadWeekPlanItems();
  }

  Future<void> loadWeekPlanItems() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final response = await wizardService.getWeekPlanItems(patientId: patientId, dietPlanId: dietPlanId, week: week);
      if (response == null || response['success'] != true) {
        errorMessage.value = 'Could not load this week\'s plan.';
        return;
      }
      final data = response['data'] as Map<String, dynamic>;
      weekDays.assignAll((data['days'] as List? ?? []).map((d) => WizardDayGroupV2.fromJson(d)).toList());
    } finally {
      loading.value = false;
    }
  }

  /// Finalizes this week (POST .../finalize-plan-item-week, sets
  /// workflowStatus:'finalized') and then activates the plan - one action
  /// for the spec's single "[ Confirm & Activate ]" button. If finalize
  /// fails, activation is not attempted.
  Future<bool> finalizeAndActivate() async {
    activating.value = true;
    errorMessage.value = null;
    try {
      final finalizeResponse = await wizardService.finalizePlanItemWeek(patientId: patientId, dietPlanId: dietPlanId);
      if (finalizeResponse == null || finalizeResponse['success'] != true) {
        errorMessage.value = finalizeResponse?['message']?.toString() ?? 'Finalize failed.';
        return false;
      }
      await wizard.patientsController.activateDietPlan(patientId, dietPlanId);
      return true;
    } finally {
      activating.value = false;
    }
  }
}
