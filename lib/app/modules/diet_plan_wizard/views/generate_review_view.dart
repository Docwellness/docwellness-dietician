import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/generate_review_controller.dart';
import '../controllers/generation_step_controller.dart';
import '../controllers/refine_portions_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';
import '../widgets/recipe_picker_list.dart';
import '../widgets/wizard_theme.dart';
import '../widgets/wizard_widgets.dart';

const _headerColor = WizardPalette.plum;
const _bodyColor = WizardPalette.ink;
const _mutedColor = WizardPalette.muted;
const _primaryColor = WizardPalette.magenta;
const _pillBg = WizardPalette.tint;

/// Step 2 (Generate) "done" phase, plan-item mode only - shown inline by
/// generation_step_view.dart instead of the plain days-array checkmark
/// screen. Renders the just-generated V1 diet as a browsable, editable
/// day-group/serving-time grid (mirrors patients/views/select_diet_sheet.dart's
/// UX for the days-array flow) - recipe cards can be opened for full detail,
/// removed, swapped, or a new one added, before moving on to Step 3 (Refine
/// Portions, ingredient-level).
class GenerateReviewView extends StatelessWidget {
  const GenerateReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<GenerateReviewController>();

    return Obx(() {
      if (controller.loading.value && controller.weekDays.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: _primaryColor));
      }
      if (controller.errorMessage.value != null && controller.weekDays.isEmpty) {
        return Center(
          child: CustomText(text: controller.errorMessage.value!, fontWeight: FontWeight.w400, fontSize: 13, color: _mutedColor),
        );
      }

      final slot = controller.currentSlot;

      return Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: CustomText(text: 'Plan generated ✓', fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
                ),
                InkWell(
                  onTap: () => _confirmAndRegenerate(context, controller),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16, color: _primaryColor),
                        SizedBox(width: 4),
                        CustomText(text: 'Regenerate', fontWeight: FontWeight.w500, fontSize: 12, color: _primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CustomText(
              text: 'Version 1 of the diet. Add or remove recipes below.',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DayGroupSegmentedControl(
              options: generateReviewDayGroups.map((dg) => MapEntry(dg, controller.dayGroupLabel(dg))).toList(),
              selected: controller.selectedDayGroup.value,
              onSelect: (dg) => controller.selectedDayGroup.value = dg,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MealSlotWrap(
              options: generateReviewServingTimes,
              selected: controller.selectedServingTime.value,
              onSelect: (t) => controller.selectedServingTime.value = t,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: slot == null
                ? const Center(
                    child: CustomText(text: 'No slot for this selection.', fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...slot.items.map((item) => _ReviewRecipeCard(item: item, controller: controller)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openAddPicker(context, controller),
                        icon: const Icon(Icons.add, size: 18, color: _primaryColor),
                        label: const CustomText(text: 'Add Recipe', fontWeight: FontWeight.w500, fontSize: 13, color: _primaryColor),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _primaryColor)),
                      ),
                      const SizedBox(height: 4),
                      const CustomText(
                        text: 'Add sides, salads, or extra dishes to this slot - you can add more than one recipe per slot.',
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: _mutedColor,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          WizardStepFooter(
            primaryLabel: 'Continue',
            onSaveExit: () => Get.back(),
            onPrimary: () {
              // Step 3 (Refine Portions) is a GetX singleton for the
              // wizard's lifetime - if it already loaded once, force it to
              // refresh and re-balance against whatever the plan items
              // actually are now, since Step 2 may have added/removed/
              // swapped one since then.
              if (Get.isRegistered<RefinePortionsStepController>()) {
                Get.find<RefinePortionsStepController>().refreshForReentry();
              }
              wizard.nextStep();
            },
          ),
        ],
      );
    });
  }

  /// The only path allowed to discard the current plan items and re-run AI
  /// generation - always confirmed first, since it's destructive and
  /// otherwise irreversible (same risk profile already accepted for Auto-
  /// Balance/Swap elsewhere in this wizard).
  Future<void> _confirmAndRegenerate(BuildContext context, GenerateReviewController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CustomText(text: 'Regenerate plan?', fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
        content: const CustomText(
          text: 'This discards the current recipes for this week and generates a fresh set. This cannot be undone.',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: _bodyColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const CustomText(text: 'Cancel', fontWeight: FontWeight.w500, fontSize: 13, color: _mutedColor),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const CustomText(text: 'Regenerate', fontWeight: FontWeight.w500, fontSize: 13, color: _headerColor),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _primaryColor)),
    );
    final generationController = Get.find<GenerationStepController>();
    await generationController.regenerateMenu();
    await controller.loadWeekPlanItems();
    if (context.mounted) Navigator.of(context).pop(); // dismiss the loading dialog
  }

  void _openAddPicker(BuildContext context, GenerateReviewController controller) {
    final slot = controller.currentSlot;
    if (slot == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecipePicker(
        title: 'Add Recipe',
        servingTime: controller.selectedServingTime.value,
        excludeRecipeIds: slot.items.map((i) => i.parentRecipeId).toSet(),
        onSelect: (recipe) => controller.addItem(recipe.id, recipe.name),
      ),
    );
  }
}

class _ReviewRecipeCard extends StatelessWidget {
  final WizardPlanItemV2 item;
  final GenerateReviewController controller;

  const _ReviewRecipeCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: WizardRecipeCard(
        title: item.recipeName,
        onTap: () => _openDetails(context),
        actions: [
          InkWell(
            onTap: () => _openSwapPicker(context),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.swap_horiz, size: 18, color: _primaryColor)),
          ),
          InkWell(
            onTap: () => controller.removeItem(item),
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 18, color: _mutedColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final parentRecipeId = item.parentRecipeId;
    if (parentRecipeId.isEmpty) return;

    // This item's recipe version - ingredients/components/steps/nutrition -
    // already came down with GET .../plan-items, so the sheet can open with
    // no network wait. Only a just-added/swapped card (a name-only stub,
    // see GenerateReviewController._stubVersion) still needs the blocking
    // GET /recipes/:id to have anything to show.
    final version = item.recipeVersion;
    RecipePreview recipeToShow;
    if (version != null && version.ingredients.isNotEmpty) {
      recipeToShow = version.toRecipePreview(servingTime: controller.selectedServingTime.value);
    } else {
      final recipe = await RecipeService().getRecipeById(parentRecipeId);
      if (recipe == null || !context.mounted) return;
      recipeToShow = recipe;
    }
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 1,
        maxChildSize: 1,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sheetScrollController) => RecipeDetailsScreen(
          fromAddRecipeScreen: false,
          isPlanItemPreview: true,
          scrollController: sheetScrollController,
          recipePreview: recipeToShow,
          onSavedAsNew: (saved) => controller.swapItem(item, saved.id, saved.name),
          onUpdateExisting: (recipe) => controller.updateItemFromRecipeSnapshot(item, recipe),
        ),
      ),
    );
  }

  void _openSwapPicker(BuildContext context) {
    final slot = controller.currentSlot;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecipePicker(
        title: 'Swap Recipe',
        servingTime: controller.selectedServingTime.value,
        excludeRecipeIds: {item.parentRecipeId, ...?slot?.items.map((i) => i.parentRecipeId)},
        onSelect: (recipe) => controller.swapItem(item, recipe.id, recipe.name),
      ),
    );
  }
}

/// Full-width 4-segment control for the day-groups - always all 4 fully
/// visible (no horizontal scroll to discover), unlike the old horizontally-
/// scrolling pill row.
class _DayGroupSegmentedControl extends StatelessWidget {
  final List<MapEntry<String, String>> options;
  final String selected;
  final void Function(String) onSelect;

  const _DayGroupSegmentedControl({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: _pillBg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: options.map((entry) {
          final isSelected = entry.key == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: CustomText(
                  text: entry.value,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: isSelected ? Colors.white : _primaryColor,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Wrapping chip row for the 7 meal slots - wraps to a second line instead
/// of clipping/scrolling, so every slot is always visible.
class _MealSlotWrap extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;

  const _MealSlotWrap({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return InkWell(
          onTap: () => onSelect(option),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : _pillBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: CustomText(
              text: option,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isSelected ? Colors.white : _primaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecipePicker extends StatefulWidget {
  final String title;
  final String servingTime;
  final Set<String> excludeRecipeIds;
  final void Function(RecipeListItem recipe) onSelect;

  const _RecipePicker({required this.title, required this.servingTime, required this.excludeRecipeIds, required this.onSelect});

  @override
  State<_RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends State<_RecipePicker> {
  final RecipeService _recipeService = RecipeService();
  List<RecipeListItem> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _recipeService.listRecipes(servingTime: widget.servingTime, limit: 50);
      if (!mounted) return;
      setState(() {
        _recipes = response.recipes.where((r) => !widget.excludeRecipeIds.contains(r.id)).toList();
        _loading = false;
      });
    } catch (e) {
      // Never leave the sheet stuck on a spinner - fall through to the
      // empty state, which reads "No other recipes for this slot."
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(text: widget.title, fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: _primaryColor)),
              )
            else if (_recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CustomText(text: 'No other recipes for this slot.', fontWeight: FontWeight.w400, fontSize: 13, color: _mutedColor),
              )
            else
              Flexible(
                child: RecipePickerList(
                  recipes: _recipes,
                  onSelect: (recipe) {
                    widget.onSelect(recipe);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
