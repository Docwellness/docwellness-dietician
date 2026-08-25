import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

import 'package:docwellnesdoc/app/utils/functions/quantity_label.dart';

import '../models/wizard_week_models.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

/// Real per-100g nutrition (and therefore a live client-side calorie
/// preview) only ever arrives for a 'g'-unit ingredient - see
/// WizardIngredientLine's own doc comment, the server never sends
/// unitConversions to the client. Switching a row to any other unit is
/// still a valid edit (the server resolves grams via FoodItem.unitConversions
/// at Save), it just can't be previewed live here - matches the same
/// "never fabricate precision the data doesn't have" honesty this file
/// already followed for the Cal header.
const _availableUnits = ['g', 'ml', 'tsp', 'tbsp', 'cup', 'piece'];

/// v4.0 Step 3's core new UI: a per-ingredient editor, not a fraction dial -
/// each row is one RecipeVersion.ingredients[] entry with a plain quantity
/// field and a unit picker (no +/- steppers - a dietician typing "150" is
/// faster than 30 taps). Saving calls
/// PlanItemFinalizeStepController.editIngredients, which creates a new
/// RecipeVersion (V2) server-side and repoints only this one PlanItem -
/// never mutates the version this sheet opened with.
///
/// The "Current: X Cal" and "Day Total" figures recompute locally on every
/// keystroke for instant feedback, summing rawQuantity * per100gCalories/100
/// across 'g'-unit rows only. The authoritative figure is always whatever
/// the server returns after Save.
class IngredientEditorSheet extends StatefulWidget {
  final WizardPlanItemV2 item;
  final double? targetCalories;
  final double dayBaselineCalories;
  final double? dailyCalorieTarget;
  final Future<bool> Function(List<WizardIngredientLine> updatedIngredients) onSave;
  // When this sheet's "Recipe Details" link leads to "Save as New Recipe",
  // this swaps the plan item onto the newly-created recipe (see
  // RecipeDetailsScreen.onSavedAsNew) - the caller (refine_portions_step_
  // view.dart) already knows this item and its own swap method.
  final Future<void> Function(String newParentRecipeId)? onSwapToNewRecipe;

  const IngredientEditorSheet({
    super.key,
    required this.item,
    this.targetCalories,
    this.dayBaselineCalories = 0,
    this.dailyCalorieTarget,
    required this.onSave,
    this.onSwapToNewRecipe,
  });

  @override
  State<IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends State<IngredientEditorSheet> {
  // Snapshot of the ingredient list as this sheet opened it - kept
  // separately from the mutable _ingredients below so _portionScaleRatio
  // always has an unedited baseline to compare against, however many edits
  // the dietician makes in this session.
  late final List<WizardIngredientLine> _originalIngredients = List.of(
    widget.item.recipeVersion?.ingredients ?? const [],
  );
  late final List<WizardIngredientLine> _ingredients = List.of(_originalIngredients);
  bool _saving = false;
  bool _loadingDetails = false;

  /// How much the ingredient list's total weight has changed since this
  /// sheet opened, based on 'g'-unit ingredients only - the same
  /// "only grams are client-computable" reasoning as _currentCalories below
  /// (no unit-conversion table is ever sent to the client). Used to
  /// live-scale the recipe's components (its real plate/serving amounts,
  /// e.g. "1 bowl") as ingredients are edited, per the ask that this math
  /// be driven by the ingredient portions themselves rather than calories.
  /// Falls back to 1 (unscaled) when there's no g-based ingredient to
  /// compare, so a components-only recipe isn't silently zeroed out.
  double get _portionScaleRatio {
    double original = 0;
    double current = 0;
    for (final ingredient in _originalIngredients) {
      if (ingredient.unit == 'g') original += ingredient.rawQuantity;
    }
    for (final ingredient in _ingredients) {
      if (ingredient.unit == 'g') current += ingredient.rawQuantity;
    }
    if (original <= 0) return 1;
    return current / original;
  }

  /// Live preview of "how much this makes" - the recipe's own components
  /// (see RecipeVersion.components, already the real-world plate/serving
  /// amount, e.g. "3 nos" Idli + "1 bowl" Sambar) scaled by how much the
  /// ingredients have grown/shrunk in this session. The authoritative,
  /// server-recomputed version is created at Save (createCustomVersion
  /// proportionally rescales components there too, off the calorie ratio) -
  /// this is only ever a same-session preview.
  List<WizardComponent> get _scaledComponents {
    final components = widget.item.recipeVersion?.components ?? const [];
    if (components.isEmpty) return const [];
    final ratio = _portionScaleRatio;
    return components
        .map((c) => WizardComponent(label: c.label, quantity: c.quantity * ratio, unit: c.unit))
        .toList();
  }

  double? get _currentCalories {
    double total = 0;
    bool anyKnown = false;
    for (final ingredient in _ingredients) {
      if (ingredient.per100gCalories == null || ingredient.unit != 'g') continue;
      anyKnown = true;
      total += (ingredient.rawQuantity / 100) * ingredient.per100gCalories!;
    }
    return anyKnown ? total : null;
  }

  /// Baseline (every other item in the day) + this recipe's live total -
  /// falls back to the last-known server total for this item when no
  /// ingredient here is grams-based (nothing local to compute from).
  double get _dayLiveTotal =>
      widget.dayBaselineCalories + (_currentCalories ?? widget.item.calories ?? 0);

  void _updateQuantity(int index, double value) {
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(rawQuantity: value);
    });
  }

  void _updateUnit(int index, String unit) {
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(unit: unit);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(_ingredients);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _viewRecipeDetails() async {
    final parentRecipeId = widget.item.parentRecipeId;
    if (parentRecipeId.isEmpty || _loadingDetails) return;
    setState(() => _loadingDetails = true);
    final recipe = await RecipeService().getRecipeById(parentRecipeId);
    if (!mounted) return;
    setState(() => _loadingDetails = false);
    if (recipe == null) return;

    // Show this item's actually-assigned recipe version's ingredients/
    // components/nutrition (already in memory - the wizard fetched it),
    // not the unrelated master Recipe document's own stored fields, which
    // can be stale/different once this item has been auto-balanced or
    // manually edited (version > 1). Uses the LIVE in-progress edit state
    // (_ingredients/_scaledComponents), not the pre-edit version snapshot -
    // tapping "Recipe Details" mid-edit (before Save) should preview what's
    // actually typed into the fields right now, matching the live "This
    // recipe: X Cal"/"Makes" preview already shown above in this same sheet.
    // cookingSteps still only carries this version's last-SAVED step text
    // (there's no per-keystroke live step text to show) - see
    // RecipePreview.copyWithVersionOverride's own doc comment on why
    // translations are always dropped alongside it.
    final version = widget.item.recipeVersion;
    final recipeToShow = version == null
        ? recipe
        : recipe.copyWithVersionOverride(
            ingredients: _ingredients
                .map(
                  (i) => Ingredient(
                    name: i.foodItemName ?? 'Ingredient',
                    quantity: i.rawQuantity,
                    unit: i.unit,
                    category: 'Other',
                    priceLevel: '₹₹',
                    description: i.preparation ?? '',
                  ),
                )
                .toList(),
            components: _scaledComponents.map((c) => RecipeComponent(label: c.label, quantity: c.quantity, unit: c.unit)).toList(),
            nutrition: version.nutritionPerServing != null ? Nutrition.fromJson(version.nutritionPerServing!) : null,
            cookingSteps: version.steps,
          );

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
          onSavedAsNew: (saved) async {
            await widget.onSwapToNewRecipe?.call(saved.id);
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final versionLabel = widget.item.recipeVersion != null
        ? 'V${widget.item.recipeVersion!.versionNumber} → Editing V${widget.item.recipeVersion!.versionNumber + 1}'
        : '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(text: widget.item.recipeName, fontWeight: FontWeight.w600, fontSize: 17, color: _headerColor),
                          if (versionLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CustomText(text: versionLabel, fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor),
                            ),
                        ],
                      ),
                    ),
                    if (widget.item.parentRecipeId.isNotEmpty)
                      InkWell(
                        onTap: _viewRecipeDetails,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: _loadingDetails
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor))
                              : const CustomText(
                                  text: 'Recipe Details',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: _primaryColor,
                                ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _RecipeSummaryHeader(
                  current: _currentCalories,
                  dayTotal: _dayLiveTotal,
                  dailyTarget: widget.dailyCalorieTarget,
                  components: _scaledComponents,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _ingredients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _IngredientRow(
                      key: ValueKey(_ingredients[index].foodItemId),
                      ingredient: _ingredients[index],
                      onQuantityChanged: (value) => _updateQuantity(index, value),
                      onUnitChanged: (unit) => _updateUnit(index, unit),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  isLoading: _saving,
                  onTap: _save,
                  text: 'Save',
                  isOutline: false,
                  buttonColor: _headerColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Calorie stats + "how much this makes" in one clean card - the latter
/// (components) only renders when the recipe actually has any, so a
/// components-less recipe just keeps the plain two-line calorie summary
/// this replaced.
class _RecipeSummaryHeader extends StatelessWidget {
  final double? current;
  final double dayTotal;
  final double? dailyTarget;
  final List<WizardComponent> components;

  const _RecipeSummaryHeader({
    required this.current,
    required this.dayTotal,
    required this.dailyTarget,
    required this.components,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xffFEF6FB), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'This Recipe',
                  value: current != null ? '${current!.round()} Cal' : '—',
                ),
              ),
              Container(width: 1, height: 30, color: _primaryColor.withOpacity(0.15)),
              const SizedBox(width: 14),
              Expanded(
                child: _StatColumn(
                  label: 'Day Total',
                  value: dailyTarget != null
                      ? '${dayTotal.round()} / ${dailyTarget!.round()} Cal'
                      : '${dayTotal.round()} Cal',
                ),
              ),
            ],
          ),
          if (components.isNotEmpty) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: _primaryColor.withOpacity(0.12))),
            const CustomText(text: 'Makes (on the plate)', fontWeight: FontWeight.w600, fontSize: 11, color: _mutedColor),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: components.map((c) {
                final formatted = formatQuantityLabel(c.quantity.toStringAsFixed(2), c.unit);
                final label = components.length > 1 && c.label.isNotEmpty ? '${c.label}: $formatted' : formatted;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: CustomText(text: label, fontWeight: FontWeight.w600, fontSize: 12, color: _primaryColor),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: label, fontWeight: FontWeight.w500, fontSize: 11, color: _mutedColor),
        const SizedBox(height: 2),
        CustomText(text: value, fontWeight: FontWeight.w700, fontSize: 15, color: _primaryColor),
      ],
    );
  }
}

class _IngredientRow extends StatefulWidget {
  final WizardIngredientLine ingredient;
  final void Function(double value) onQuantityChanged;
  final void Function(String unit) onUnitChanged;

  const _IngredientRow({
    super.key,
    required this.ingredient,
    required this.onQuantityChanged,
    required this.onUnitChanged,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late final TextEditingController _controller = TextEditingController(text: _formatQty(widget.ingredient.rawQuantity));

  static String _formatQty(double q) => q % 1 == 0 ? q.toStringAsFixed(0) : q.toStringAsFixed(1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// This ingredient's own calorie contribution - only computable for a
  /// 'g'-unit ingredient with per100gCalories (see WizardIngredientLine's
  /// own doc comment on why other units never carry that figure). "—"
  /// otherwise, never a guessed/wrong number.
  String get _calorieLabel {
    final per100g = widget.ingredient.per100gCalories;
    if (widget.ingredient.unit != 'g' || per100g == null) return '—';
    return '${((widget.ingredient.rawQuantity / 100) * per100g).round()} Cal';
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.ingredient.unit;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: widget.ingredient.foodItemName ?? 'Ingredient',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: _bodyColor,
              ),
              const SizedBox(height: 2),
              CustomText(text: _calorieLabel, fontWeight: FontWeight.w400, fontSize: 11, color: _mutedColor),
            ],
          ),
        ),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _bodyColor),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primaryColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primaryColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
            ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null && parsed >= 0) widget.onQuantityChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: _primaryColor), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availableUnits.contains(unit) ? unit : null,
              hint: CustomText(text: unit, fontWeight: FontWeight.w500, fontSize: 12, color: _bodyColor),
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: _primaryColor, size: 18),
              items: _availableUnits
                  .map((u) => DropdownMenuItem(value: u, child: CustomText(text: u, fontWeight: FontWeight.w500, fontSize: 12, color: _bodyColor)))
                  .toList(),
              onChanged: (u) {
                if (u != null) widget.onUnitChanged(u);
              },
            ),
          ),
        ),
      ],
    );
  }
}
