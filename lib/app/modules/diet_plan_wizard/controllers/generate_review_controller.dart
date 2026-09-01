import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
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
    // The Add / Swap pickers' recipe lists come from the catalog
    // WizardController.onInit already warmed in one request - no per-slot
    // prefetch here anymore. prefetchWizardCatalog() is idempotent, so this
    // is just a backstop for a deep-link straight onto this step.
    recipeService.prefetchWizardCatalog();
  }

  /// Reads through WizardController's shared week plan-items cache so
  /// entering this step doesn't re-run the heavy join Step 4's generation
  /// guard (or a previous visit to this step) already paid for. Pass
  /// [forceRefresh] after a mutation that isn't reflected locally.
  Future<void> loadWeekPlanItems({bool forceRefresh = false}) async {
    loading.value = true;
    errorMessage.value = null;
    try {
      final response = await wizard.loadWeekPlanItems(forceRefresh: forceRefresh);
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

  // ── Add / remove / swap ──────────────────────────────────────────────
  // These update `weekDays` in place and skip the full-week refetch that
  // getWeekPlanItems does (a large response the wizard used to re-pull
  // after every single tap, which made this screen feel very slow).
  // Step 3 (Refine) re-loads everything with full ingredient data on entry
  // - a card added/swapped here only needs to show a name until then, so a
  // lightweight local RecipeVersion stub is enough. On any backend
  // rejection we surface the message and resync from the server.

  Future<void> addItem(String recipeId, String recipeName) async {
    final mealSlotId = currentSlot?.mealSlotId;
    if (mealSlotId == null) return;
    final result = await wizardService.addPlanItem(
      patientId: patientId,
      dietPlanId: dietPlanId,
      mealSlotId: mealSlotId,
      recipeId: recipeId,
    );
    if (result == null || result['success'] != true) {
      _showItemActionError(result, 'Could not add that recipe.');
      return;
    }
    final planItem = result['data']?['planItem'] as Map<String, dynamic>?;
    _insertItemLocally(
      mealSlotId,
      WizardPlanItemV2(
        id: planItem?['_id']?.toString() ?? '',
        recipeVersionId: planItem?['recipeVersionId']?.toString() ?? '',
        recipeVersion: _stubVersion(recipeId, recipeName, planItem?['recipeVersionId']?.toString()),
        locked: false,
        isLinkedComponent: false,
      ),
    );
    // The optimistic update above keeps THIS screen right; drop the shared
    // cache so Step 3 (Refine) refetches the real, fully-joined item.
    wizard.invalidateWeekPlanItems();
  }

  Future<void> removeItem(WizardPlanItemV2 item) async {
    _removeItemLocally(item.id); // instant - reconcile only if the server disagrees
    final result = await wizardService.removePlanItem(
      patientId: patientId,
      dietPlanId: dietPlanId,
      planItemId: item.id,
    );
    if (result == null || result['success'] != true) {
      _showItemActionError(result, 'Could not remove that recipe.');
      await loadWeekPlanItems(forceRefresh: true);
      return;
    }
    wizard.invalidateWeekPlanItems();
  }

  Future<void> swapItem(WizardPlanItemV2 item, String recipeId, String recipeName) async {
    final result = await wizardService.swapRecipeVersion(
      patientId: patientId,
      dietPlanId: dietPlanId,
      planItemId: item.id,
      newParentRecipeId: recipeId,
    );
    if (result == null || result['success'] != true) {
      _showItemActionError(result, 'Could not swap that recipe.');
      return;
    }
    final swapped = result['data']?['item'] as Map<String, dynamic>?;
    _replaceItemLocally(
      item.id,
      WizardPlanItemV2(
        id: item.id,
        recipeVersionId: swapped?['recipeVersionId']?.toString() ?? item.recipeVersionId,
        recipeVersion: _stubVersion(recipeId, recipeName, swapped?['recipeVersionId']?.toString()),
        locked: item.locked,
        pinned: item.pinned,
        isLinkedComponent: item.isLinkedComponent,
      ),
    );
    wizard.invalidateWeekPlanItems();
  }

  WizardRecipeVersion _stubVersion(String recipeId, String recipeName, String? recipeVersionId) => WizardRecipeVersion(
        id: recipeVersionId ?? '',
        parentRecipeId: recipeId,
        name: recipeName,
        versionNumber: 1,
        ingredients: const [],
        steps: const [],
        hasUnresolvedIngredients: false,
      );

  void _removeItemLocally(String itemId) {
    for (final day in weekDays) {
      for (final meal in day.meals) {
        meal.items.removeWhere((i) => i.id == itemId);
      }
    }
    weekDays.refresh();
  }

  void _insertItemLocally(String mealSlotId, WizardPlanItemV2 item) {
    for (final day in weekDays) {
      for (final meal in day.meals) {
        if (meal.mealSlotId == mealSlotId) {
          meal.items.add(item);
          weekDays.refresh();
          return;
        }
      }
    }
  }

  void _replaceItemLocally(String itemId, WizardPlanItemV2 replacement) {
    for (final day in weekDays) {
      for (final meal in day.meals) {
        final idx = meal.items.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          meal.items[idx] = replacement;
          weekDays.refresh();
          return;
        }
      }
    }
  }

  /// A plan-item add/swap can be rejected by the backend (most commonly a
  /// recipe with unresolved ingredients - a 404 with an explanatory
  /// message). Without this the failure was swallowed and the tap looked
  /// like it did nothing.
  void _showItemActionError(dynamic result, String fallback) {
    final ctx = Get.overlayContext;
    if (ctx == null) return;
    final message = (result is Map && result['message'] is String && (result['message'] as String).trim().isNotEmpty)
        ? result['message'] as String
        : fallback;
    showAppToast(ctx, message: message, type: AppToastType.warning);
  }

  /// "Update Existing" on Recipe Details' AI-regenerated preview - see
  /// RefinePortionsStepController.updateItemFromRecipeSnapshot's identical
  /// doc comment.
  Future<bool> updateItemFromRecipeSnapshot(WizardPlanItemV2 item, RecipePreview recipe) async {
    final result = await wizardService.updateItemRecipeVersion(
      patientId: patientId,
      dietPlanId: dietPlanId,
      planItemId: item.id,
      recipe: {
        'name': recipe.name,
        'ingredients': recipe.ingredients
            .map((i) => {'name': i.name, 'quantity': i.quantity, 'unit': i.unit})
            .toList(),
        'cookingSteps': recipe.cookingSteps,
        'components': recipe.components.map((c) => c.toJson()).toList(),
      },
    );
    final ok = result != null && result['success'] == true;
    if (ok) await loadWeekPlanItems(forceRefresh: true);
    return ok;
  }
}
