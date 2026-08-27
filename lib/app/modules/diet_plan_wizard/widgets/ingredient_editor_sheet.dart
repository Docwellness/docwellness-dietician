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

const _availableUnits = ['g', 'ml', 'tsp', 'tbsp', 'cup', 'piece'];

/// One ingredient's calorie contribution at its current rawQuantity/unit -
/// resolvedGramsPerUnit (see WizardIngredientLine's own doc comment) is
/// already the grams-equivalent of ONE unit of whatever unit this
/// ingredient is currently in (1 for 'g' itself, ~40 for a 'piece' of
/// Chapati, etc.), server-resolved via FoodItem.unitConversions/density -
/// so this works identically for every unit, not just grams. Null (never a
/// guessed number) when either figure is unresolvable - a freshly-switched
/// unit invalidates resolvedGramsPerUnit (see copyWith), correctly falling
/// back to null/"—" until the version is re-fetched after Save.
double? _ingredientCalories(WizardIngredientLine ingredient) {
  final per100g = ingredient.per100gCalories;
  final gramsPerUnit = ingredient.resolvedGramsPerUnit;
  if (per100g == null || gramsPerUnit == null) return null;
  return (ingredient.rawQuantity * gramsPerUnit / 100) * per100g;
}

/// v4.0 Step 3's core new UI: a per-ingredient editor, not a fraction dial -
/// each row is one RecipeVersion.ingredients[] entry with a plain quantity
/// field and a unit picker (no +/- steppers - a dietician typing "150" is
/// faster than 30 taps). Saving calls
/// PlanItemFinalizeStepController.editIngredients, which creates a new
/// RecipeVersion (V2) server-side and repoints only this one PlanItem -
/// never mutates the version this sheet opened with.
///
/// The "Current: X Cal" and "Day Total" figures recompute locally on every
/// keystroke for instant feedback, summing each ingredient's rawQuantity *
/// resolvedGramsPerUnit/100 * per100gCalories (see _ingredientCalories) -
/// works for any unit, not just grams, as long as the server could resolve
/// a conversion for it. The authoritative figure is always whatever the
/// server returns after Save.
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
  // When this sheet's "Recipe Details" link leads to "Update Existing" (see
  // RecipeDetailsScreen.onUpdateExisting), applies the AI-regenerated
  // recipe to just this plan item - the caller already knows this item and
  // its own RefinePortionsStepController.updateItemFromRecipeSnapshot.
  final Future<bool> Function(RecipePreview updatedRecipe)? onUpdateExisting;

  const IngredientEditorSheet({
    super.key,
    required this.item,
    this.targetCalories,
    this.dayBaselineCalories = 0,
    this.dailyCalorieTarget,
    required this.onSave,
    this.onSwapToNewRecipe,
    this.onUpdateExisting,
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

  /// How much the ingredient list's total weight (in grams-equivalent, via
  /// each ingredient's own resolvedGramsPerUnit - see WizardIngredientLine's
  /// doc comment) has changed since this sheet opened. Used to live-scale
  /// the recipe's components (its real plate/serving amounts, e.g. "1
  /// bowl") as ingredients are edited, per the ask that this math be driven
  /// by the ingredient portions themselves rather than calories. Only
  /// ingredients with a resolvable weight count toward either side (an
  /// ingredient with no known conversion contributes to neither, rather
  /// than being treated as 0 and skewing the ratio). Falls back to 1
  /// (unscaled) when there's nothing resolvable to compare, so a
  /// components-only recipe isn't silently zeroed out.
  double get _portionScaleRatio {
    double original = 0;
    double current = 0;
    for (final ingredient in _originalIngredients) {
      final grams = ingredient.resolvedGramsPerUnit;
      if (grams != null) original += ingredient.rawQuantity * grams;
    }
    for (final ingredient in _ingredients) {
      final grams = ingredient.resolvedGramsPerUnit;
      if (grams != null) current += ingredient.rawQuantity * grams;
    }
    if (original <= 0) return 1;
    return current / original;
  }

  /// recipe-core-ingredient-scaling: same computation as [_portionScaleRatio]
  /// above, but summed only over `role == 'core'` ingredients - drives the
  /// live sub-ingredient recompute in [_updateQuantity]/[_updateUnit]. When
  /// no ingredient has `role == 'core'` (a not-yet-migrated recipe, per the
  /// backend's own "inert, not an error" fallback), both totals are 0 and
  /// this returns 1 (the existing divide-by-zero guard) - the recompute
  /// becomes a no-op automatically, with no separate "does this recipe
  /// support this feature" branch needed anywhere else.
  double get _coreScaleRatio {
    double original = 0;
    double current = 0;
    for (final ingredient in _originalIngredients) {
      if (ingredient.role != 'core') continue;
      final grams = ingredient.resolvedGramsPerUnit;
      if (grams != null) original += ingredient.rawQuantity * grams;
    }
    for (final ingredient in _ingredients) {
      if (ingredient.role != 'core') continue;
      final grams = ingredient.resolvedGramsPerUnit;
      if (grams != null) current += ingredient.rawQuantity * grams;
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
      final calories = _ingredientCalories(ingredient);
      if (calories == null) continue;
      anyKnown = true;
      total += calories;
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
      _recomputeSubIngredientsIfCoreChanged(index);
    });
  }

  void _updateUnit(int index, String unit) {
    setState(() {
      _ingredients[index] = _ingredients[index].copyWith(unit: unit);
      _recomputeSubIngredientsIfCoreChanged(index);
    });
  }

  /// recipe-core-ingredient-scaling: only fires when the JUST-edited
  /// ingredient is 'core' (editing a 'sub' ingredient directly never
  /// triggers this, it only ever updates its own entry). Recomputes EVERY
  /// 'sub' ingredient's rawQuantity unconditionally from its ORIGINAL
  /// (sheet-open snapshot) value times the current core-group ratio - not
  /// from whatever is currently in [_ingredients], and not skipped even
  /// when the ratio comes out to ~1 (e.g. rebalancing carrots vs. peas
  /// within a multi-core group nets back to the original total after two
  /// separate edits) - `original * 1` already IS the correct "unchanged"
  /// value, so there is nothing to special-case. This is what correctly
  /// resets a sub ingredient back to its original value if a prior edit
  /// had temporarily scaled it away from 1:1 and a later edit brings the
  /// core group's total back to where it started - unlike the server's
  /// single-shot createCustomVersion (services/recipeVersioningService.js),
  /// this recompute can run many times across many keystrokes in one
  /// session, so it always derives fresh from `original`, never from its
  /// own last output.
  ///
  /// Unconditionally overwriting also means a sub ingredient that was
  /// unlocked via Override gets its typed value discarded here too, exactly
  /// per this feature's design - see the resulting change surfacing
  /// through _IngredientRowState.didUpdateWidget, which reverts that row's
  /// Override lock alongside syncing its displayed text.
  void _recomputeSubIngredientsIfCoreChanged(int editedIndex) {
    if (_ingredients[editedIndex].role != 'core') return;
    final ratio = _coreScaleRatio;
    for (var i = 0; i < _ingredients.length; i++) {
      final ingredient = _ingredients[i];
      if (ingredient.role != 'sub') continue;
      final original = _originalIngredients.firstWhere(
        (o) => o.foodItemId == ingredient.foodItemId,
        orElse: () => ingredient,
      );
      _ingredients[i] = ingredient.copyWith(rawQuantity: original.rawQuantity * ratio);
    }
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
          onUpdateExisting: widget.onUpdateExisting,
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
  final FocusNode _focusNode = FocusNode();

  // recipe-core-ingredient-scaling: a 'sub' ingredient's field starts
  // read-only and stays that way until this dietician explicitly taps
  // Override for THIS row, in THIS sheet session - see design.md's
  // Decisions for why (surfaces, rather than hides, the two-step
  // limitation: a core edit afterward discards a sub override).
  bool _subOverrideUnlocked = false;

  static String _formatQty(double q) => q % 1 == 0 ? q.toStringAsFixed(0) : q.toStringAsFixed(1);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// A sub ingredient's [rawQuantity]/[unit] only ever changes from
  /// OUTSIDE this row via _recomputeSubIngredientsIfCoreChanged (a core
  /// ingredient elsewhere was edited) - core ingredients are only ever
  /// changed by this row's own [onChanged]. Sync the controller to match
  /// (skipped while this field has focus, so an in-progress core edit
  /// never has its own cursor/selection disturbed by a DIFFERENT row's
  /// rebuild), and revert a sub override back to locked - its old typed
  /// value was just discarded by the recompute, so the field should look
  /// locked again rather than editable-but-stale.
  @override
  void didUpdateWidget(covariant _IngredientRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedExternally =
        widget.ingredient.rawQuantity != oldWidget.ingredient.rawQuantity || widget.ingredient.unit != oldWidget.ingredient.unit;
    if (changedExternally && !_focusNode.hasFocus) {
      _controller.text = _formatQty(widget.ingredient.rawQuantity);
      if (_subOverrideUnlocked) _subOverrideUnlocked = false;
    }
  }

  /// This ingredient's own calorie contribution - "—" only when genuinely
  /// unresolvable (see _ingredientCalories), never a guessed/wrong number.
  String get _calorieLabel {
    final calories = _ingredientCalories(widget.ingredient);
    return calories == null ? '—' : '${calories.round()} Cal';
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.ingredient.unit;
    final isCore = widget.ingredient.role == 'core';
    final isLocked = !isCore && !_subOverrideUnlocked;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: CustomText(
                      text: widget.ingredient.foodItemName ?? 'Ingredient',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: _bodyColor,
                    ),
                  ),
                  if (isCore) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: const CustomText(text: 'Core', fontWeight: FontWeight.w700, fontSize: 9, color: _primaryColor),
                    ),
                  ],
                ],
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
            focusNode: _focusNode,
            readOnly: isLocked,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isLocked ? _mutedColor : _bodyColor),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              filled: isLocked,
              fillColor: isLocked ? _mutedColor.withOpacity(0.06) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isLocked ? _mutedColor.withOpacity(0.3) : _primaryColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isLocked ? _mutedColor.withOpacity(0.3) : _primaryColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
            ),
            onChanged: isLocked
                ? null
                : (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed >= 0) widget.onQuantityChanged(parsed);
                  },
          ),
        ),
        if (!isCore) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => setState(() => _subOverrideUnlocked = !_subOverrideUnlocked),
            icon: Icon(_subOverrideUnlocked ? Icons.lock_open : Icons.lock_outline, size: 16, color: _mutedColor),
            tooltip: _subOverrideUnlocked ? 'Locked to core proportions' : 'Override this amount manually',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
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
