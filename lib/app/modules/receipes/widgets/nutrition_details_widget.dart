import 'dart:math';

import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart'
    show SupplementFacts;
import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';

// %DV reference values: FDA 2020 label base table (design.md, Decision 9).
// Trans fat and total sugar have no DV, so they have no constant here.
const double dvFat = 78; // g
const double dvSaturatedFat = 20; // g
const double dvCarbs = 275; // g
const double dvFiber = 28; // g
const double dvProtein = 50; // g
const double dvCholesterol = 300; // mg
const double dvSodium = 2300; // mg
const double dvCalcium = 1300; // mg
const double dvIron = 18; // mg
const double dvPotassium = 4700; // mg
const double dvVitaminC = 90; // mg

/// "3.1mg" for a researched value, "—" when it is unknown (null). A null is
/// never shown as 0: 0 is a finding, null is "not researched". A positive value
/// that would round to "0" at one decimal shows "<0.1", so only a true 0 reads
/// "0mg".
String microValueText(num? value, String unit) {
  if (value == null) return '—';
  if (_isTrace(value)) return '<0.1$unit';
  final text = value.toStringAsFixed(1);
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}$unit';
}

/// Positive but below the 0.05 that one decimal can show.
bool _isTrace(num value) => value > 0 && value < 0.05;

/// "%DV" text, blank when the value is unknown, the nutrient has no DV, or the
/// value is a trace (shown as "<0.1").
String dvPercentText(num? value, double? dailyValue) {
  if (value == null || dailyValue == null || _isTrace(value)) return '';
  return '${((value / dailyValue) * 100).toStringAsFixed(0)}%';
}

/// "%DV" text for a macro row (fat, protein, carbs, fiber). Macros always show
/// their %DV, even a small one ("0%"); the trace rule above is for the
/// micronutrient rows only.
String macroDvPercentText(num value, double dailyValue) =>
    '${((value / dailyValue) * 100).toStringAsFixed(0)}%';

/// Ring fractions for the macro circles. Protein, fat and carbs are their share
/// of energy (4P / 9F / 4C) and add up to 100%. Fiber is already inside carbs,
/// so it is shown as its share of the carbs rather than added on top of them.
({double protein, double fats, double carbs, double fiber}) macroRingShares({
  required num protein,
  required num fats,
  required num carbs,
  required num fiber,
}) {
  final energy = 4 * protein + 9 * fats + 4 * carbs;
  if (energy <= 0) return (protein: 0.25, fats: 0.25, carbs: 0.25, fiber: 0.25);
  return (
    protein: 4 * protein / energy,
    fats: 9 * fats / energy,
    carbs: 4 * carbs / energy,
    fiber: carbs > 0 ? (fiber / carbs).clamp(0.0, 1.0).toDouble() : 0.0,
  );
}

class NutritionDetailsWidget extends StatefulWidget {
  final Nutrition? nutrition;
  // Real active-ingredient facts for a supplement recipe - when present,
  // this replaces the whole macro/DV view below (which is meaningless for
  // a vitamin/mineral tablet - its `nutrition` is intentionally zeroed).
  final SupplementFacts? supplementFacts;

  const NutritionDetailsWidget({
    super.key,
    this.nutrition,
    this.supplementFacts,
  });

  @override
  State<NutritionDetailsWidget> createState() => _NutritionDetailsWidgetState();
}

class _NutritionDetailsWidgetState extends State<NutritionDetailsWidget> {
  bool isVisibil = true;

  num get protein => widget.nutrition?.protein ?? 0;
  num get fats => widget.nutrition?.fats ?? 0;
  num get carbs => widget.nutrition?.carbs ?? 0;
  num get fiber => widget.nutrition?.fiber ?? 0;
  num get calories => widget.nutrition?.calories ?? 0;

  Nutrition? get _n => widget.nutrition;

  ({double protein, double fats, double carbs, double fiber}) get _rings =>
      macroRingShares(protein: protein, fats: fats, carbs: carbs, fiber: fiber);
  double get proteinPercent => _rings.protein;
  double get fatsPercent => _rings.fats;
  double get carbsPercent => _rings.carbs;
  double get fiberPercent => _rings.fiber;

  bool get _isSupplement =>
      widget.supplementFacts != null &&
      widget.supplementFacts!.nutrients.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isSupplement) return _buildSupplementFacts(widget.supplementFacts!);
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Container(
          padding: EdgeInsets.only(top: 16, left: 19, bottom: 8, right: 19),
          decoration: BoxDecoration(
            color: Color(0xffFEF6FB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: cardBorder,
            boxShadow: cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NutritionCircle(
                title: "Protein",
                grams: protein.toDouble(),
                percent: proteinPercent,
              ),
              NutritionCircle(
                title: "Fat",
                grams: fats.toDouble(),
                percent: fatsPercent,
              ),
              NutritionCircle(
                title: "Carbs",
                grams: carbs.toDouble(),
                percent: carbsPercent,
              ),
              NutritionCircle(
                // Its % is fiber as a share of carbs, not of energy.
                title: "Fiber (of carbs)",
                grams: fiber.toDouble(),
                percent: fiberPercent,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        //---------------- SERVING SIZE BAR ----------------
        GestureDetector(
          onTap: () {
            setState(() {
              isVisibil = !isVisibil;
            });
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xff851653),
              borderRadius: BorderRadius.circular(11),
              boxShadow: cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: "Per Serving",
                    color: Color(0xffFCFCFD),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  Icon(
                    isVisibil == false
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: Color(0xffFCFCFD),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        //---------------- CALORIES BLOCK ----------------
        Visibility(
          visible: isVisibil,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pinkContainer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: "Calories",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111927),
                    ),
                    CustomText(
                      text: "${calories.toStringAsFixed(0)} kcal",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff111927),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              //---------------- TOTAL FAT ----------------
              nutritionItem(
                title: "Total fat",
                value: "${fats.toStringAsFixed(1)}g",
                dv: macroDvPercentText(fats, dvFat),
                sub: [
                  SubNutrition(
                    title: "Saturated fat",
                    value: microValueText(_n?.saturatedFat, "g"),
                    dv: dvPercentText(_n?.saturatedFat, dvSaturatedFat),
                  ),
                  SubNutrition(
                    title: "Trans fat",
                    value: microValueText(_n?.transFat, "g"),
                    dv: "",
                  ),
                ],
              ),

              nutritionItem(
                title: "Protein",
                value: "${protein.toStringAsFixed(1)}g",
                dv: macroDvPercentText(protein, dvProtein),
              ),

              nutritionItem(
                title: "Total Carbohydrates",
                value: "${carbs.toStringAsFixed(1)}g",
                dv: macroDvPercentText(carbs, dvCarbs),
                sub: [
                  SubNutrition(
                    title: "Dietary Fiber",
                    value: "${fiber.toStringAsFixed(1)}g",
                    dv: macroDvPercentText(fiber, dvFiber),
                  ),
                  SubNutrition(
                    title: "Sugar",
                    value: microValueText(_n?.sugar, "g"),
                    dv: "",
                  ),
                ],
              ),

              nutritionItem(
                title: "Cholesterol",
                value: microValueText(_n?.cholesterol, "mg"),
                dv: dvPercentText(_n?.cholesterol, dvCholesterol),
              ),
              nutritionItem(
                title: "Sodium",
                value: microValueText(_n?.sodium, "mg"),
                dv: dvPercentText(_n?.sodium, dvSodium),
              ),
              nutritionItem(
                title: "Calcium",
                value: microValueText(_n?.calcium, "mg"),
                dv: dvPercentText(_n?.calcium, dvCalcium),
              ),
              nutritionItem(
                title: "Iron",
                value: microValueText(_n?.iron, "mg"),
                dv: dvPercentText(_n?.iron, dvIron),
              ),
              nutritionItem(
                title: "Potassium",
                value: microValueText(_n?.potassium, "mg"),
                dv: dvPercentText(_n?.potassium, dvPotassium),
              ),
              nutritionItem(
                title: "Vitamin C",
                value: microValueText(_n?.vitaminC, "mg"),
                dv: dvPercentText(_n?.vitaminC, dvVitaminC),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Drops a trailing ".0" (e.g. 300.0 -> "300"), keeps real decimals
  /// (e.g. 56.3 -> "56.3") - JSON numbers can arrive as either int or
  /// double depending on how Mongo stored them.
  String _formatNum(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  /// Real per-serving active-ingredient facts (name, amount, %NRV) for a
  /// supplement - see SupplementFacts. Replaces the macro-circle/fake-DV
  /// view above, which doesn't apply to a vitamin/mineral tablet.
  Widget _buildSupplementFacts(SupplementFacts facts) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        if (facts.brand.isNotEmpty || facts.servingLabel.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff851653),
              borderRadius: BorderRadius.circular(11),
              boxShadow: cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facts.brand.isNotEmpty)
                  CustomText(
                    text: facts.brand,
                    color: const Color(0xffFCFCFD),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                if (facts.servingLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CustomText(
                      text: 'Per serving: ${facts.servingLabel}',
                      color: const Color(0xffFCE7F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ...facts.nutrients.map(
          (n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: pinkContainer(
              child: nutritionRow(
                n.name,
                '${_formatNum(n.amount)}${n.unit.isNotEmpty ? ' ${n.unit}' : ''}',
                n.percentNRV != null ? '${_formatNum(n.percentNRV!)}% NRV' : '',
                bold: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

//
// PINK SECTION CONTAINER
//
Widget pinkContainer({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xffFEF6FB),
      borderRadius: BorderRadius.circular(8),
      boxShadow: cardShadow,
    ),
    child: child,
  );
}

//
// MAIN NUTRITION ITEM
//
Widget nutritionItem({
  required String title,
  required String value,
  required String dv,
  List<SubNutrition>? sub,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: pinkContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: nutritionRow(title, value, dv, bold: true),
          ),
          if (sub != null)
            ...sub.map((e) => nutritionRow("   ${e.title}", e.value, e.dv)),
        ],
      ),
    ),
  );
}

//
// SINGLE ROW
//
Widget nutritionRow(
  String title,
  String value,
  String dv, {
  bool bold = false,
}) {
  return Row(
    children: [
      Expanded(
        child: CustomText(
          text: title,
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: const Color(0xff384250),
        ),
      ),
      CustomText(
        text: value,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xff384250),
      ),
      const SizedBox(width: 12),
      CustomText(
        text: dv,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xff384250),
      ),
    ],
  );
}

//
// MODEL
//
class SubNutrition {
  final String title;
  final String value;
  final String dv;

  const SubNutrition({
    required this.title,
    required this.value,
    required this.dv,
  });
}

class NutritionCircle extends StatelessWidget {
  final String title;
  final double grams;
  final double percent;

  const NutritionCircle({
    super.key,
    required this.title,
    required this.grams,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          width: 54,
          child: CustomPaint(
            painter: _CirclePainter(percent),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${grams.toInt()}g",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff530630),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "${(percent * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w300,
                      color: Color(0xff530630),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Fit the title to the circle's width so a long one ("Fiber (of
        // carbs)") shrinks instead of widening the ring row.
        SizedBox(
          width: 54,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Color(0xff530630),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percent;
  _CirclePainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = const Color(0xffFCE7F6)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xffDE2493)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Full background circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      backgroundPaint,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percent,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
