import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

import '../models/wizard_week_models.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

/// v4.0 Step 3's core new UI: a per-ingredient gram-scale editor, not a
/// fraction dial - each row is one RecipeVersion.ingredients[] entry with
/// its own +/- stepper. Saving calls
/// PlanItemFinalizeStepController.editIngredients, which creates a new
/// RecipeVersion (V2) server-side and repoints only this one PlanItem -
/// never mutates the version this sheet opened with.
///
/// The "Current: X Cal" header recomputes locally on every stepper tap for
/// instant feedback, summing rawQuantity * per100gCalories/100 across rows
/// that have per100gCalories (only ingredients authored in grams carry that
/// figure from the backend - see WizardIngredientLine's own doc comment).
/// The authoritative figure is always whatever the server returns after
/// Save.
class IngredientEditorSheet extends StatefulWidget {
  final WizardPlanItemV2 item;
  final double? targetCalories;
  final Future<bool> Function(List<WizardIngredientLine> updatedIngredients) onSave;

  const IngredientEditorSheet({
    super.key,
    required this.item,
    this.targetCalories,
    required this.onSave,
  });

  @override
  State<IngredientEditorSheet> createState() => _IngredientEditorSheetState();
}

class _IngredientEditorSheetState extends State<IngredientEditorSheet> {
  late final List<WizardIngredientLine> _ingredients = List.of(
    widget.item.recipeVersion?.ingredients ?? const [],
  );
  bool _saving = false;

  double? get _currentCalories {
    double total = 0;
    bool anyKnown = false;
    for (final ingredient in _ingredients) {
      if (ingredient.per100gCalories == null) continue;
      anyKnown = true;
      total += (ingredient.rawQuantity / 100) * ingredient.per100gCalories!;
    }
    return anyKnown ? total : null;
  }

  void _adjust(int index, double delta) {
    final current = _ingredients[index];
    final next = (current.rawQuantity + delta).clamp(0, 100000).toDouble();
    setState(() {
      _ingredients[index] = current.copyWith(rawQuantity: next);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(_ingredients);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
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
                CustomText(
                  text: widget.item.recipeName,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: _headerColor,
                ),
                if (versionLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: CustomText(text: versionLabel, fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor),
                  ),
                const SizedBox(height: 10),
                _CaloriesHeader(current: _currentCalories, target: widget.targetCalories),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _ingredients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _IngredientRow(
                      ingredient: _ingredients[index],
                      onAdjust: (delta) => _adjust(index, delta),
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

class _CaloriesHeader extends StatelessWidget {
  final double? current;
  final double? target;

  const _CaloriesHeader({required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xffFEF6FB), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              text: current != null ? 'Current: ${current!.round()} Cal' : 'Current: —',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _primaryColor,
            ),
          ),
          if (target != null)
            CustomText(
              text: 'Target: ${target!.round()} Cal',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: _mutedColor,
            ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final WizardIngredientLine ingredient;
  final void Function(double delta) onAdjust;

  const _IngredientRow({required this.ingredient, required this.onAdjust});

  /// Coarser steps for larger existing quantities (e.g. 5g for a 200g
  /// portion, 1g for a 10g spice) rather than one fixed step size that's
  /// either too fine or too coarse across wildly different ingredient scales.
  double get _step {
    if (ingredient.rawQuantity >= 100) return 10;
    if (ingredient.rawQuantity >= 20) return 5;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: ingredient.foodItemName ?? 'Ingredient',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: _bodyColor,
          ),
        ),
        _StepperButton(icon: Icons.remove, onTap: () => onAdjust(-_step)),
        Container(
          width: 64,
          alignment: Alignment.center,
          child: CustomText(
            text: '${ingredient.rawQuantity.toStringAsFixed(ingredient.rawQuantity % 1 == 0 ? 0 : 1)} ${ingredient.unit}',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: _bodyColor,
          ),
        ),
        _StepperButton(icon: Icons.add, onTap: () => onAdjust(_step)),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(border: Border.all(color: _primaryColor), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: _primaryColor),
      ),
    );
  }
}
