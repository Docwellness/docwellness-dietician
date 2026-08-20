import 'package:docwellnesdoc/app/modules/diet_plan_wizard/models/wizard_week_models.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/services/diet_plan_wizard_service.dart';
import 'package:get/get.dart';

import 'wizard_controller.dart';

/// Step 5 (Finalize & Clever Adjustments) - has two sub-states:
///
/// 1. Draft review (isFinalized == false): shows what the engine (AI or
///    deterministic, see services/recipeSelectionEngine.js on the backend)
///    selected per day-group/slot, from GET .../draft-options. "Finalize
///    Week" submits those selections as-is via the existing
///    PUT .../finalize-week endpoint.
/// 2. Clever Adjustments (isFinalized == true): Week Tweak / Exception
///    Review / Swap vs Scale - the Phase 3 endpoints operate on the typed
///    days[] schema, which (see finalizeWeekPlan's dual-write comment on
///    the backend) is only ever populated by an actual finalize - so these
///    tools only become meaningful, and are only shown, after step 1 above.
class FinalizeStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();

  final RxBool loading = false.obs;
  final RxBool isFinalized = false.obs;
  final RxnString errorMessage = RxnString();

  // --- Draft review state ---
  final RxList<Map<String, dynamic>> draftDayGroups = <Map<String, dynamic>>[].obs;
  final RxBool finalizing = false.obs;

  // --- Clever Adjustments state ---
  final RxList<WizardDayGroup> weekDays = <WizardDayGroup>[].obs;
  final RxList<WizardCalorieException> calorieExceptions = <WizardCalorieException>[].obs;
  final RxDouble tolerancePercent = 10.0.obs;
  final RxBool activating = false.obs;

  String get patientId => wizard.patientId;
  String get dietPlanId => wizard.dietPlanId.value ?? '';
  int get week => wizard.targetWeek.value;

  @override
  void onInit() {
    super.onInit();
    if (dietPlanId.isNotEmpty) loadDraftOptions();
  }

  Future<void> loadDraftOptions() async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final response = await wizard.patientsController.service
          .getDraftWeekOptions(patientId, dietPlanId, week);
      if (response == null || response['success'] != true) {
        errorMessage.value = 'Could not load this week\'s draft.';
        return;
      }
      final data = response['data'] as Map<String, dynamic>;
      isFinalized.value = data['isFinalized'] == true;
      draftDayGroups.assignAll(
        List<Map<String, dynamic>>.from(data['dayGroups'] ?? []),
      );

      if (isFinalized.value) {
        await Future.wait([loadWeekDays(), loadExceptions()]);
      }
    } finally {
      loading.value = false;
    }
  }

  /// Flattens draftDayGroups' isSelected recipes into finalize-week's
  /// selectedMeals payload shape - see buildFinalizeWeekPayload's backend
  /// counterpart (cleanSelectedMeals) for the exact fields it accepts.
  List<Map<String, dynamic>> _buildSelectedMealsFromDraft() {
    final meals = <Map<String, dynamic>>[];
    for (final dayGroup in draftDayGroups) {
      final dg = dayGroup['dayGroup'];
      for (final servingTimeEntry in (dayGroup['servingTimes'] as List? ?? [])) {
        final servingTime = servingTimeEntry['servingTime'];
        for (final recipe in (servingTimeEntry['recipes'] as List? ?? [])) {
          if (recipe['isSelected'] != true) continue;
          meals.add({
            'dayGroup': dg,
            'servingTime': servingTime,
            'recipeId': recipe['id'],
            'servings': recipe['servings'] ?? 1,
          });
        }
      }
    }
    return meals;
  }

  Future<bool> finalizeThisWeek() async {
    finalizing.value = true;
    errorMessage.value = null;
    try {
      final selectedMeals = _buildSelectedMealsFromDraft();
      if (selectedMeals.isEmpty) {
        errorMessage.value =
            'Nothing was generated for this week yet - go back and generate before finalizing.';
        return false;
      }
      final response = await wizard.patientsController.service.finalizeWeek({
        'week': week,
        'selectedMeals': selectedMeals,
      }, patientId, dietPlanId);

      if (response == null || response['success'] != true) {
        errorMessage.value = response?['message']?.toString() ?? 'Finalize failed.';
        return false;
      }
      isFinalized.value = true;
      await Future.wait([loadWeekDays(), loadExceptions()]);
      return true;
    } finally {
      finalizing.value = false;
    }
  }

  Future<void> loadWeekDays() async {
    final response = await wizardService.getWeekDays(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
    );
    if (response == null) return;
    final data = response['data'] as Map<String, dynamic>;
    weekDays.assignAll(
      (data['days'] as List? ?? [])
          .map((d) => WizardDayGroup.fromJson(d))
          .toList(),
    );
  }

  Future<void> loadExceptions() async {
    final response = await wizardService.getExceptions(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
    );
    if (response == null) return;
    final data = response['data'] as Map<String, dynamic>;
    tolerancePercent.value = (data['tolerancePercent'] as num?)?.toDouble() ?? 10.0;
    calorieExceptions.assignAll(
      (data['calorieExceptions'] as List? ?? [])
          .map((e) => WizardCalorieException.fromJson(e))
          .toList(),
    );
  }

  Future<void> applyWeekTweak(String servingTime, double multiplier) async {
    final result = await wizardService.applyWeekTweak(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
      servingTime: servingTime,
      multiplier: multiplier,
    );
    if (result != null && result['success'] == true) {
      await Future.wait([loadWeekDays(), loadExceptions()]);
    }
  }

  Future<void> scaleItem(WizardPlanItem item, String dayGroup, String servingTime, double newMultiplier) async {
    final result = await wizardService.scaleItem(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
      dayGroup: dayGroup,
      servingTime: servingTime,
      itemId: item.itemId,
      newMultiplier: newMultiplier,
    );
    if (result != null && result['success'] == true) {
      await Future.wait([loadWeekDays(), loadExceptions()]);
    }
  }

  Future<List<WizardSwapAlternative>> getAlternatives({
    required WizardPlanItem item,
    required String dayGroup,
    required String servingTime,
    String? direction,
  }) async {
    final response = await wizardService.getSwapAlternatives(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
      dayGroup: dayGroup,
      servingTime: servingTime,
      itemId: item.itemId,
      direction: direction,
    );
    if (response == null) return [];
    final alternatives = (response['data']?['alternatives'] as List? ?? [])
        .map((a) => WizardSwapAlternative.fromJson(a))
        .toList();
    return alternatives;
  }

  Future<void> swapItem({
    required WizardPlanItem item,
    required String dayGroup,
    required String servingTime,
    required String newRecipeId,
    String? reason,
  }) async {
    final result = await wizardService.swapRecipe(
      patientId: patientId,
      dietPlanId: dietPlanId,
      week: week,
      dayGroup: dayGroup,
      servingTime: servingTime,
      itemId: item.itemId,
      newRecipeId: newRecipeId,
      reason: reason,
    );
    if (result != null && result['success'] == true) {
      await Future.wait([loadWeekDays(), loadExceptions()]);
    }
  }

  Future<bool> activatePlan() async {
    activating.value = true;
    try {
      await wizard.patientsController.activateDietPlan(patientId, dietPlanId);
      return true;
    } finally {
      activating.value = false;
    }
  }
}
