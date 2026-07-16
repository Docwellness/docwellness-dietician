import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
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

  // Servings +/- stepper - optional (nullable callbacks), so callers that
  // don't wire it (e.g. a read-only card) simply don't render it. Only
  // shown while the card is selected, since adjusting servings for an
  // unselected item has no effect on the plan.
  final num? currentServings;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  // Opens the recipe's full detail (ingredients/instructions) in a bottom
  // sheet - optional, so callers that don't wire it just show a
  // non-interactive image/name (tapping does nothing, same as before).
  final VoidCallback? onTapDetails;

  // A second, independent +/- stepper for compound snacks that combine a
  // countable fruit with a scoopable mix-in (e.g. "Banana with Roasted
  // Chana and Seeds" - the primary badge/stepper above is the banana, this
  // is the seeds) - see Recipe.hasSecondaryComponent. Optional, same
  // nullable-callback pattern as the primary stepper: only rendered when
  // both callbacks and a label are provided.
  final String? secondaryLabel;
  final String secondaryUnit;
  final num? secondaryCurrentServings;
  final VoidCallback? onSecondaryIncrement;
  final VoidCallback? onSecondaryDecrement;

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
    this.currentServings,
    this.onIncrement,
    this.onDecrement,
    this.onTapDetails,
    this.secondaryLabel,
    this.secondaryUnit = '',
    this.secondaryCurrentServings,
    this.onSecondaryIncrement,
    this.onSecondaryDecrement,
    this.supplementNutrientLabels,
  });

  bool get _isSupplement =>
      supplementNutrientLabels != null && supplementNutrientLabels!.isNotEmpty;

  // 15g ≈ 1 tbsp - the same approximation the source diet plans
  // themselves use ("rice (10 tbsp)" ≈ 150g rice).
  static const num _gramsPerTablespoon = 15;
  // 250ml ≈ 1 cup (the standard metric/Indian recipe cup).
  static const num _mlPerCup = 250;

  /// Formats a raw numeric quantity string for display: piece-based units
  /// get fraction notation (1/4, 1/2, 3/4, 1 1/2...) instead of a raw
  /// decimal; ml-based units get an approximate cup count (also in fraction
  /// notation); gram-based units get an approximate tablespoon count.
  static String _formatQuantityLabel(String rawValue, String unit) {
    final value = num.tryParse(rawValue);
    if (value == null) {
      return unit.isNotEmpty ? '$rawValue $unit' : rawValue;
    }
    if (unit == 'piece') {
      return '${_formatPieceFraction(value)} $unit';
    }
    if (unit == 'ml') {
      final cups = _formatPieceFraction(value / _mlPerCup);
      return '$rawValue $unit (~$cups cup)';
    }
    // Already a spoon measure (e.g. a secondaryComponent like "Seeds &
    // Chana" - see Recipe.hasSecondaryComponent) - no further conversion,
    // converting it again as if it were grams would be wrong.
    if (unit == 'tbsp' || unit == 'tsp') {
      return '$rawValue $unit';
    }
    if (unit.isNotEmpty) {
      final tbsp = (value / _gramsPerTablespoon).round();
      return '$rawValue $unit (~$tbsp tbsp)';
    }
    return rawValue;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffFDF2FA)),
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(16),
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
                    Row(
                      children: [
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
                            text: _formatQuantityLabel(grams, unit),

                            color: Color(0xff851653),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        if (!_isSupplement) ...[
                          const SizedBox(width: 5),
                          CustomText(
                            text: "$calorie calorie",

                            fontWeight: FontWeight.w400,
                            color: Color(0xff6C737F),
                            fontSize: 12,
                          ),
                        ],
                      ],
                    ),
                    if (isSelected &&
                        onIncrement != null &&
                        onDecrement != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ServingsStepButton(
                            icon: Icons.remove,
                            onTap: onDecrement!,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 48),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: CustomText(
                              text: currentServings != null
                                  ? _formatQuantityLabel(
                                      '$currentServings',
                                      unit,
                                    )
                                  : '',
                              color: Color(0xff384250),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          _ServingsStepButton(
                            icon: Icons.add,
                            onTap: onIncrement!,
                          ),
                        ],
                      ),
                    ],
                    if (isSelected &&
                        secondaryLabel != null &&
                        onSecondaryIncrement != null &&
                        onSecondaryDecrement != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CustomText(
                            text: '$secondaryLabel: ',
                            color: Color(0xff6C737F),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                          _ServingsStepButton(
                            icon: Icons.remove,
                            onTap: onSecondaryDecrement!,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 48),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: CustomText(
                              text: secondaryCurrentServings != null
                                  ? _formatQuantityLabel(
                                      '$secondaryCurrentServings',
                                      secondaryUnit,
                                    )
                                  : '',
                              color: Color(0xff384250),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          _ServingsStepButton(
                            icon: Icons.add,
                            onTap: onSecondaryIncrement!,
                          ),
                        ],
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
