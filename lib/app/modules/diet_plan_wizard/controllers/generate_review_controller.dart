import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/functions/day_group_label.dart' as day_group_label;
import 'package:get/get.dart';

import '../models/wizard_week_models.dart';
import '../services/diet_plan_wizard_service.dart';
import 'wizard_controller.dart';

const List<String> generateReviewServingTimes = [
  'Morning Drink',
  'Breakfast',
  'Brunch',
  'Lunch',
  'Evening Snack',
  'Dinner',
  'Night Drink',
];

const List<String> generateReviewDayGroups = ['Monday', 'Tuesday', 'Wednesday', 'Thursday'];

/// Step 2 (Generate), new-plan-item-flow only: once generate-menu has run
/// (see generation_step_controller.dart), this drives the day-group/
/// serving-time-tabbed review of what got selected - "shows only the V1
/// Recipe Name... next to the name a swap icon" per the v4.0 spec, plus
/// add/remove (spec only mentions swap, but a dietician needs to be able to
/// add an extra dish or drop one with no replacement too - see
/// controllers/dietician/planItemController.js's addPlanItem/removePlanItem).
class GenerateReviewController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();
  final RecipeService recipeService = RecipeService();

  final RxBool loading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxList<WizardDayGroupV2> weekDays = <WizardDayGroupV2>[].obs;
  final RxString selectedDayGroup = generateReviewDayGroups.first.obs;
  final RxString selectedServingTime = generateReviewServingTimes.first.obs;

  String get patientId => wizard.patientId;
  String get dietPlanId => wizard.dietPlanId.value ?? '';
  int get week => wizard.targetWeek.value;

  String dayGroupLabel(String dayGroup) => day_group_label.dayGroupLabel(dayGroup);

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

  WizardMealSlotV2? get currentSlot {
    final day = weekDays.cast<WizardDayGroupV2?>().firstWhere((d) => d?.dayGroup == selectedDayGroup.value, orElse: () => null);
    if (day == null) return null;
    return day.meals.cast<WizardMealSlotV2?>().firstWhere((m) => m?.servingTime == selectedServingTime.value, orElse: () => null);
  }

  Future<void> addItem(String recipeId) async {
    final mealSlotId = currentSlot?.mealSlotId;
    if (mealSlotId == null) return;
    final result = await wizardService.addPlanItem(patientId: patientId, dietPlanId: dietPlanId, mealSlotId: mealSlotId, recipeId: recipeId);
    if (result != null && result['success'] == true) await loadWeekPlanItems();
  }

  Future<void> removeItem(WizardPlanItemV2 item) async {
    final result = await wizardService.removePlanItem(patientId: patientId, dietPlanId: dietPlanId, planItemId: item.id);
    if (result != null && result['success'] == true) await loadWeekPlanItems();
  }

  Future<void> swapItem(WizardPlanItemV2 item, String newParentRecipeId) async {
    final result = await wizardService.swapRecipeVersion(
      patientId: patientId,
      dietPlanId: dietPlanId,
      planItemId: item.id,
      newParentRecipeId: newParentRecipeId,
    );
    if (result != null && result['success'] == true) await loadWeekPlanItems();
  }
}
