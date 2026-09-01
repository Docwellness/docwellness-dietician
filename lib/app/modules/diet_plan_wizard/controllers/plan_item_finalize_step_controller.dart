import 'package:docwellnesdoc/app/utils/functions/day_group_label.dart';
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
/// every item, then "Finalize Plan" which locks the week (status ->
/// Finalized). Activation is deliberately NOT part of this step: a plan
/// goes Active only once the patient's payment is confirmed, from the
/// payment screen (payment_status_view.dart -> activateDietPlan).
class PlanItemFinalizeStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<WizardDayGroupV2> weekDays = <WizardDayGroupV2>[].obs;
  final RxBool finalizing = false.obs;

  /// Which day-group's meal timeline the Review screen is showing (the
  /// screen renders one day-group at a time now, selected from a chip row at
  /// the top - diet-plan-wizard/finalize-step). Empty until the first load
  /// picks the first day-group that has items.
  final RxString selectedDayGroup = ''.obs;

  // Same tolerance as services/planActivationService.js's
  // ACTIVATION_CALORIE_TOLERANCE - kept in sync manually since this is a
  // proactive client-side mirror of the server-side gate, not a replacement
  // for it (the server still re-validates on finalize).
  static const double _activationCalorieTolerance = 0.05;

  String get patientId => wizard.patientId;
  String get dietPlanId => wizard.dietPlanId.value ?? '';
  int get week => wizard.targetWeek.value;

  /// The Step 1 calorie budget, or null if it was never set (Step 1 should
  /// always set it before Generation runs, but a resumed/regenerated plan
  /// could in principle skip that - see finalizePlan/the backend's
  /// own 400 for the same missing-target case).
  double? get targetCalories =>
      (wizard.patientsController.selectedCalorieStrategy['calorieBudget'] as num?)?.toDouble();

  /// Per-day {dayGroup, totalCalories, withinTolerance} - only for days that
  /// actually have generated items, mirroring
  /// services/planActivationService.js::validatePlanForActivation exactly so
  /// this proactive check and the server's blocking check never disagree.
  List<({String dayGroup, double totalCalories, bool withinTolerance})> get dayCalorieChecks {
    final target = targetCalories;
    if (target == null || target <= 0) return const [];
    return weekDays.where((day) => day.hasItems).map((day) {
      final total = day.totalCalories;
      final deviation = (total - target).abs() / target;
      return (dayGroup: day.dayGroup, totalCalories: total, withinTolerance: deviation <= _activationCalorieTolerance);
    }).toList();
  }

  /// False whenever finalize would be rejected by the server anyway (no
  /// target set, or any generated day outside +/-5%) - drives the Finalize
  /// Plan button's disabled state so the dietician sees the block before
  /// tapping, not just as an error message after.
  bool get canActivate {
    final target = targetCalories;
    if (target == null || target <= 0) return false;
    final checks = dayCalorieChecks;
    return checks.every((day) => day.withinTolerance);
  }

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
      // Keep the current selection if it still has items, else fall back to
      // the first day-group that does.
      final withItems = weekDays.where((d) => d.hasItems).toList();
      if (withItems.isNotEmpty && !withItems.any((d) => d.dayGroup == selectedDayGroup.value)) {
        selectedDayGroup.value = withItems.first.dayGroup;
      }
    } finally {
      loading.value = false;
    }
  }

  /// Day-groups that have generated meals, as (canonical value, display
  /// label) pairs for the selector.
  List<MapEntry<String, String>> get selectableDayGroups =>
      weekDays.where((d) => d.hasItems).map((d) => MapEntry(d.dayGroup, dayGroupLabel(d.dayGroup))).toList();

  /// The day-group the timeline is currently showing, or null before load.
  WizardDayGroupV2? get selectedDay {
    for (final day in weekDays) {
      if (day.dayGroup == selectedDayGroup.value) return day;
    }
    return null;
  }

  /// Finalizes this week (POST .../finalize-plan-item-week: sets
  /// workflowStatus:'finalized' and promotes the plan Draft -> Finalized).
  /// Activation is a separate, later step gated on the patient's payment
  /// (see payment_status_view.dart) - it is intentionally not done here.
  Future<bool> finalizePlan() async {
    finalizing.value = true;
    errorMessage.value = null;
    try {
      final finalizeResponse = await wizardService.finalizePlanItemWeek(patientId: patientId, dietPlanId: dietPlanId);
      if (finalizeResponse == null) {
        // Service returns null only when the request never got a response
        // (timeout / offline / 5xx with no body) - a data-level rejection
        // still comes back as a Map with success:false and a message.
        errorMessage.value = 'Couldn\'t reach the server to finalize this plan. Check your connection and try again.';
        return false;
      }
      if (finalizeResponse['success'] != true) {
        errorMessage.value = finalizeResponse['message']?.toString() ?? 'Finalize failed.';
        return false;
      }
      await wizard.patientsController.getPatientProfile(patientId);
      return true;
    } finally {
      finalizing.value = false;
    }
  }
}
