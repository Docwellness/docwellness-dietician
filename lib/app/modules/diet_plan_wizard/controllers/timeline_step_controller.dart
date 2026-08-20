import 'package:docwellnesdoc/app/modules/diet_plan_wizard/services/diet_plan_wizard_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:get/get.dart';

import 'wizard_controller.dart';

const List<String> requiredServingTimes = [
  'Morning Drink',
  'Breakfast',
  'Brunch',
  'Lunch',
  'Evening Snack',
  'Dinner',
  'Night Drink',
];

const List<String> dayGroups = ['Monday', 'Tuesday', 'Wednesday', 'Thursday'];

class StagedSupplement {
  final String dayGroup;
  final String servingTime;
  final String supplementId;
  final String supplementName;
  final String? dosage;
  final String? instructions;
  final String timingAnchor; // 'pre' | 'with' | 'post'

  const StagedSupplement({
    required this.dayGroup,
    required this.servingTime,
    required this.supplementId,
    required this.supplementName,
    this.dosage,
    this.instructions,
    required this.timingAnchor,
  });
}

/// Step 3 (Timeline Builder): supplement injection against the plan's fixed
/// 7-slot x 4-day-group timeline. Supplements are staged locally here (not
/// sent to the backend yet) because the diet plan itself doesn't exist until
/// Step 4 (Generation) creates it - POST .../supplements needs a real
/// dietPlanId. WizardController flushes stagedSupplements to the backend
/// once generation succeeds (see generation_step_controller.dart).
class TimelineStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();
  final RecipeService recipeService = RecipeService();

  final RxList<StagedSupplement> stagedSupplements = <StagedSupplement>[].obs;
  final RxList<RecipeListItem> availableSupplements = <RecipeListItem>[].obs;
  final RxBool loadingSupplements = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvailableSupplements();
  }

  Future<void> loadAvailableSupplements() async {
    loadingSupplements.value = true;
    try {
      final response = await recipeService.listRecipes(
        category: 'Supplements',
        limit: 100,
      );
      availableSupplements.assignAll(response.recipes);
    } finally {
      loadingSupplements.value = false;
    }
  }

  void addSupplement(StagedSupplement supplement) {
    // A given {dayGroup, servingTime, supplementId} slot only ever holds one
    // entry - re-adding replaces it, matching upsertSupplementForSlot's own
    // upsert-by-id semantics on the backend.
    stagedSupplements.removeWhere(
      (s) =>
          s.dayGroup == supplement.dayGroup &&
          s.servingTime == supplement.servingTime &&
          s.supplementId == supplement.supplementId,
    );
    stagedSupplements.add(supplement);
  }

  void removeSupplement(StagedSupplement supplement) {
    stagedSupplements.remove(supplement);
  }

  /// Called once Step 4 (Generation) has created a real dietPlanId. Returns
  /// the count of supplements that failed to save, for the caller to warn
  /// about (generation itself still succeeded - a supplement failing to
  /// attach shouldn't be reported as if the whole plan failed).
  ///
  /// v4.0: picks the target endpoint from wizard.dataModel (set by
  /// generation_step_controller.dart right before calling this) - the
  /// staging above is identical for both data models, only where it lands
  /// on the backend differs (days[].meals[].supplements[] vs a standalone
  /// SupplementItem document).
  Future<int> flushToBackend({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    final isPlanItem = wizard.dataModel.value == 'plan-item';
    int failures = 0;
    for (final supplement in stagedSupplements) {
      final result = isPlanItem
          ? await wizardService.upsertTimelineSupplement(
              patientId: patientId,
              dietPlanId: dietPlanId,
              week: week,
              dayGroup: supplement.dayGroup,
              servingTime: supplement.servingTime,
              supplementRecipeId: supplement.supplementId,
              dosage: supplement.dosage,
              instructions: supplement.instructions,
              timingAnchor: supplement.timingAnchor,
            )
          : await wizardService.upsertSupplement(
              patientId: patientId,
              dietPlanId: dietPlanId,
              week: week,
              dayGroup: supplement.dayGroup,
              servingTime: supplement.servingTime,
              supplementId: supplement.supplementId,
              dosage: supplement.dosage,
              instructions: supplement.instructions,
              timingAnchor: supplement.timingAnchor,
            );
      if (result == null || result['success'] != true) failures++;
    }
    return failures;
  }
}
