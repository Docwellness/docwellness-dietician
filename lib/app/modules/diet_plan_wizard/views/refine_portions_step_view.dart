import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/day_group_label.dart';
import 'package:docwellnesdoc/app/utils/functions/quantity_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/refine_portions_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';
import '../widgets/ingredient_editor_sheet.dart';
import '../widgets/recipe_picker_list.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

/// Step 3 (Refine Portions), new-plan-item-flow only - see
/// refine_portions_step_controller.dart for the rationale.
class RefinePortionsStepView extends StatelessWidget {
  const RefinePortionsStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<RefinePortionsStepController>();

    if (wizard.dietPlanId.value == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CustomText(
            text: 'Generate a plan first (Step 2) before refining portions.',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: _mutedColor,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator(color: _primaryColor));
      }
      if (controller.errorMessage.value != null && controller.weekDays.isEmpty) {
        return Center(
          child: CustomText(
            text: controller.errorMessage.value!,
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: _mutedColor,
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const CustomText(
                    text: 'Refine Portions',
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    color: _headerColor,
                  ),
                  const SizedBox(height: 4),
                  const CustomText(
                    text: 'Portions are automatically balanced toward the calorie target. Tap a recipe to edit exact ingredient quantities.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: _mutedColor,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: controller.weekDays.map((day) => _DayGroupCard(day: day, controller: controller)).toList(),
                  ),
                  if (controller.errorMessage.value != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CustomText(
                        text: controller.errorMessage.value!,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: const Color(0xffDC2626),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              onTap: wizard.nextStep,
              text: 'Continue',
              isOutline: false,
              buttonColor: _headerColor,
            ),
          ),
        ],
      );
    });
  }
}

class _DayGroupCard extends StatelessWidget {
  final WizardDayGroupV2 day;
  final RefinePortionsStepController controller;

  const _DayGroupCard({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xffFDF2FA)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: dayGroupLabel(day.dayGroup), fontWeight: FontWeight.w600, fontSize: 14, color: _bodyColor),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final required = controller.dailyCalorieTarget;
              final selected = controller.dayGroupSelectedCalories(day);
              return CustomText(
                text: required != null
                    ? 'Total Budget: Selected Calories ${selected.round()} / Required Calories ${required.round()}'
                    : 'Selected Calories ${selected.round()}',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: _mutedColor,
              );
            },
          ),
          const SizedBox(height: 6),
          ...day.meals.expand(
            (meal) => meal.items.map(
              (item) => _RecipeCard(servingTime: meal.servingTime, item: item, day: day, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final String servingTime;
  final WizardPlanItemV2 item;
  final WizardDayGroupV2 day;
  final RefinePortionsStepController controller;

  const _RecipeCard({required this.servingTime, required this.item, required this.day, required this.controller});

  /// Real-world serving quantity (e.g. "2 piece", "1 bowl") from the
  /// recipe version's components - one label per component, joined with a
  /// prefix only when there's more than one AND the label isn't just the
  /// recipe's own name repeated (matches food_card_widget.dart's own
  /// _unselectedQuantityLabels convention). Empty when the version predates
  /// the components field and has none to show.
  String? get _quantityLabel {
    final components = item.recipeVersion?.components ?? const [];
    if (components.isEmpty) return null;
    final labels = components.map((c) {
      final formatted = formatQuantityLabel('${c.quantity}', c.unit);
      if (components.length > 1 && c.label != item.recipeName) {
        return '${c.label}: $formatted';
      }
      return formatted;
    });
    return labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final quantityLabel = _quantityLabel;
    return InkWell(
      onTap: item.locked || item.recipeVersion == null ? null : () => _openIngredientEditor(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xffFAFAFA), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: '$servingTime · ${item.recipeName}',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: _bodyColor,
                  ),
                  if (item.calories != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: CustomText(
                        text: [
                          if (quantityLabel != null) quantityLabel,
                          '${item.calories!.round()} Cal',
                          'V${item.recipeVersion?.versionNumber ?? 1}',
                        ].join(' · '),
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: _mutedColor,
                      ),
                    ),
                ],
              ),
            ),
            if (item.locked) const Icon(Icons.lock, size: 16, color: _mutedColor),
            if (item.isLinkedComponent) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, size: 16, color: _mutedColor)),
            if (!item.locked)
              InkWell(
                onTap: () => _openSwapPicker(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.swap_horiz, size: 18, color: _primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openIngredientEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => IngredientEditorSheet(
        item: item,
        dayBaselineCalories: controller.dayGroupSelectedCalories(day) - (item.calories ?? 0),
        dailyCalorieTarget: controller.dailyCalorieTarget,
        onSave: (updated) => controller.editIngredients(item, updated),
        onSwapToNewRecipe: (newId) => controller.swapRecipe(item, newId),
      ),
    );
  }

  void _openSwapPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SwapRecipePicker(
        servingTime: servingTime,
        excludeRecipeId: item.parentRecipeId,
        onSelect: (recipe) => controller.swapRecipe(item, recipe.id),
      ),
    );
  }
}

class _SwapRecipePicker extends StatefulWidget {
  final String servingTime;
  final String excludeRecipeId;
  final void Function(RecipeListItem recipe) onSelect;

  const _SwapRecipePicker({required this.servingTime, required this.excludeRecipeId, required this.onSelect});

  @override
  State<_SwapRecipePicker> createState() => _SwapRecipePickerState();
}

class _SwapRecipePickerState extends State<_SwapRecipePicker> {
  final RecipeService _recipeService = RecipeService();
  List<RecipeListItem> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _recipeService.listRecipes(servingTime: widget.servingTime, limit: 50);
    if (!mounted) return;
    setState(() {
      _recipes = response.recipes.where((r) => r.id != widget.excludeRecipeId).toList();
      _loading = false;
    });
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
            const CustomText(text: 'Swap Recipe', fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
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
                  showCalories: true,
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
