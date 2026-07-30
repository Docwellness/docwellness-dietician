import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';

class FoodCard extends StatelessWidget {
  final String name;
  final String grams;
  final String calorie;
  final String protein;
  final String fiber;
  final String carbs;
  final String fat;
  final VoidCallback onSelect;
  final String? nextWeekTag;
  final String image;

  final bool isSelected;

  // Unit label for the `grams` badge (e.g. "g", "ml", "piece") - shown
  // alongside the number so it's never a bare, ambiguous figure sitting
  // next to the calorie text.
  final String unit;

  // Opens the recipe's full detail (ingredients/instructions) in a bottom
  // sheet - optional, so callers that don't wire it just show a
  // non-interactive image/name (tapping does nothing, same as before).
  final VoidCallback? onTapDetails;

  // One independently-adjustable +/- stepper per recipe component (see
  // Recipe.components) - e.g. Idli/Sambar/Chutney renders 3, an ordinary
  // single-quantity recipe renders 1. Only shown while the card is
  // selected, since adjusting servings for an unselected item has no
  // effect on the plan. Empty for a read-only card that doesn't wire
  // selection at all.
  final List<FoodCardComponentData> components;

  // Pre-formatted "name amount unit · x% NRV" labels (see
  // SupplementNutrient.displayLabel) for a supplement recipe - when
  // non-null and non-empty, these replace the calorie text and the
  // Protein/Fiber/Carbs/Fat row below, since those macro numbers are
  // meaningless (zeroed) for a vitamin/mineral tablet.
  final List<String>? supplementNutrientLabels;

  const FoodCard({
    super.key,
    required this.isSelected,
    required this.name,
    required this.grams,
    required this.calorie,
    required this.protein,
    required this.fiber,
    required this.carbs,
    required this.fat,
    required this.onSelect,
    this.nextWeekTag,
    required this.image,
    this.unit = '',
    this.onTapDetails,
    this.components = const [],
    this.supplementNutrientLabels,
  });

  bool get _isSupplement =>
      supplementNutrientLabels != null && supplementNutrientLabels!.isNotEmpty;

  // 15g ≈ 1 tbsp - the same approximation the source diet plans
  // themselves use ("rice (10 tbsp)" ≈ 150g rice).
  static const num _gramsPerTablespoon = 15;
  // 250ml ≈ 1 cup (the standard metric/Indian recipe cup).
  static const num _mlPerCup = 250;

  /// Formats a raw numeric quantity string for display: a genuinely
  /// ambiguous mass/volume (plain "g"/"ml") gets an approximate tbsp/cup
  /// hint alongside it, since a bare gram figure is hard to picture. Every
  /// other unit - piece, nos, egg, slice, bowl, cup, tbsp, tsp - is already
  /// a real, human-sized measure (see COMPONENT_UNITS on the backend) and
  /// gets clean fraction notation (1/4, 1/2, 3/4, 1 1/2...) with no
  /// further conversion - converting "2 egg" into "~0 tbsp" would be
  /// nonsensical, not helpful.
  static String _formatQuantityLabel(String rawValue, String unit) {
    final value = num.tryParse(rawValue);
    if (value == null) {
      return unit.isNotEmpty ? '$rawValue $unit' : rawValue;
    }
    if (unit == 'ml') {
      final cups = _formatPieceFraction(value / _mlPerCup);
      return '$rawValue $unit (~$cups cup)';
    }
    if (unit == 'g') {
      final tbsp = (value / _gramsPerTablespoon).round();
      return '$rawValue $unit (~$tbsp tbsp)';
    }
    if (unit.isEmpty) return rawValue;
    return '${_formatPieceFraction(value)} $unit';
  }

  static String _formatPieceFraction(num value) {
    final whole = value.floor();
    final frac = value - whole;
    String fracLabel = '';
    if ((frac - 0.25).abs() < 0.01) {
      fracLabel = '¼';
    } else if ((frac - 0.5).abs() < 0.01) {
      fracLabel = '½';
    } else if ((frac - 0.75).abs() < 0.01) {
      fracLabel = '¾';
    } else if (frac > 0.01) {
      fracLabel = frac.toStringAsFixed(2);
    }
    if (whole == 0 && fracLabel.isNotEmpty) return fracLabel;
    if (fracLabel.isEmpty) return '$whole';
    return '$whole $fracLabel';
  }

  /// One formatted string per component for the unselected-state quantity
  /// pill(s) - falls back to the legacy single grams/unit pair when a
  /// caller doesn't pass [components] at all (e.g. update_patient_diet_
  /// sheet.dart's read-only list, which has no per-component data).
  /// Labeled per component only when there's more than one AND the label
  /// isn't just the recipe's own name repeated (a migration artifact for
  /// recipes predating the components model - see scripts/migrate-recipe-
  /// components.js - where that would be redundant with the card title).
  List<String> _unselectedQuantityLabels() {
    if (components.isEmpty) {
      return [_formatQuantityLabel(grams, unit)];
    }
    return components.map((c) {
      final formatted = _formatQuantityLabel('${c.quantity}', c.unit);
      if (components.length > 1 && c.label != name) {
        return '${c.label}: $formatted';
      }
      return formatted;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: cardBorder,
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onTapDetails,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    image: image.isNotEmpty && image.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: (image.isEmpty || !image.startsWith('http'))
                        ? const Color(0xffFDF2FA)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: (image.isEmpty || !image.startsWith('http'))
                      ? const Icon(
                          Icons.restaurant,
                          color: Color(0xffEF45B2),
                          size: 24,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onTapDetails,
                      child: CustomText(
                        text: name,

                        color: Color(0xff384250),
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // The static quantity pill(s) only make sense when
                        // there's nothing else showing this recipe's
                        // quantity - once selected, the per-component
                        // stepper list below already shows each
                        // component's own live quantity, so repeating it
                        // here would just be the same number(s) twice. One
                        // pill per component (labeled, when there's more
                        // than one and the label isn't just the recipe's
                        // own name) so a multi-part dish like "Banana: 1
                        // nos, Oats Pancakes: 2 nos" isn't silently
                        // collapsed down to only its first part - a Wrap
                        // (not a Row) so any number of pills plus the
                        // calorie text always lay out safely regardless of
                        // card width.
                        if (!isSelected)
                          for (final pillText in _unselectedQuantityLabels())
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xffEF45B2)),
                                color: const Color(0xffFCE7F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomText(
                                text: pillText,
                                color: Color(0xff851653),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                        if (!_isSupplement)
                          CustomText(
                            text: "$calorie calorie",

                            fontWeight: FontWeight.w400,
                            color: Color(0xff6C737F),
                            fontSize: 12,
                          ),
                      ],
                    ),
                    if (isSelected && components.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // One stepper row per independently-adjustable
                      // component (see Recipe.components) - a compound
                      // dish like Idli with Sambar and Chutney gets one
                      // row per item, each with its own real unit; an
                      // ordinary single-quantity recipe just gets one row
                      // with no label (the card title already names it).
                      for (final component in components)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              // Same redundant-label suppression as the
                              // unselected pills above (see
                              // _unselectedQuantityLabels) - a component
                              // whose label just repeats the recipe's own
                              // name (legacy-migrated data) adds nothing
                              // the card title doesn't already say, and
                              // for a genuinely long real label, Flexible +
                              // ellipsis keeps the row from ever
                              // overflowing regardless of card width.
                              if (components.length > 1 &&
                                  component.label != name) ...[
                                Flexible(
                                  child: CustomText(
                                    text: component.label,
                                    color: Color(0xff6C737F),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              _ServingsStepButton(
                                icon: Icons.remove,
                                onTap: component.onDecrement,
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: CustomText(
                                  text: _formatQuantityLabel(
                                    '${component.quantity}',
                                    component.unit,
                                  ),
                                  color: Color(0xff384250),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              _ServingsStepButton(
                                icon: Icons.add,
                                onTap: component.onIncrement,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onSelect,
                    child: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: nextWeekTag != null
                          ? Color(0xff6C737F)
                          : isSelected
                          ? Color(0xff851653)
                          : Color(0xff49454F),
                      size: 25,
                    ),
                  ),
                  SizedBox(height: 6),
                  // Container(
                  //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  //   decoration: BoxDecoration(
                  //     border: Border.all(color: Color(0xffEF45B2)),
                  //     color: Color(0xffFCE7F6),
                  //     borderRadius: BorderRadius.circular(7),
                  //   ),
                  //   child: CustomText(
                  //     text:  'Alternative',
                  //     fontWeight: FontWeight.w500,
                  //     fontSize: 11,
                  //     color: Color(0xff851653),
                  //   ),
                  // ),
                  if (nextWeekTag != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xff4D5761)),
                        color: Color(0xffE5E7EB),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: CustomText(
                        text: nextWeekTag ?? "",
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Color(0xff384250),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reusable bottom indicators - a supplement shows its real
          // active-ingredient facts (horizontally scrollable, since e.g. a
          // multivitamin can list 20+ nutrients) instead of the macro
          // pills, which are meaningless (zeroed) for it.
          if (_isSupplement)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final label in supplementNutrientLabels!)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFDF2FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        text: label,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: const Color(0xff851653),
                      ),
                    ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FoodInfoIndicator(
                  value: "${protein}g",
                  label: "Protein",
                  icon: 'assets/icons/diet1.png',
                ),
                FoodInfoIndicator(
                  value: "${fiber}g",
                  label: "Fiber",
                  icon: 'assets/icons/diet2.png',
                ),
                FoodInfoIndicator(
                  value: "${carbs}g",
                  label: "Carbs",
                  icon: 'assets/icons/diet3.png',
                ),
                FoodInfoIndicator(
                  value: "${fat}g",
                  label: "Fat",
                  icon: 'assets/icons/diet4.png',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One independently-adjustable +/- stepper for a single recipe component
/// (see Recipe.components / FoodCard.components) - e.g. "Idli: 3 nos".
class FoodCardComponentData {
  final String label;
  final num quantity;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const FoodCardComponentData({
    required this.label,
    required this.quantity,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
  });
}

class _ServingsStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ServingsStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xff851653),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class FoodInfoIndicator extends StatelessWidget {
  final String value;
  final String label;
  final String icon;

  const FoodInfoIndicator({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Vertical progress bar
        Image.asset(icon, height: 24, width: 24),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: value,

              color: Color(0xff384250),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            CustomText(
              text: label,

              color: Color(0xff6C737F),
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ],
        ),
      ],
    );
  }
}
