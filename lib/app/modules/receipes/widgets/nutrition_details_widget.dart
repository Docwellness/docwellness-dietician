import 'dart:math';

import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class NutritionDetailsWidget extends StatefulWidget {
  final Nutrition? nutrition;

  const NutritionDetailsWidget({super.key, this.nutrition});

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

  double get total => (protein + fats + carbs + fiber).toDouble();
  double get proteinPercent => total > 0 ? protein / total : 0.25;
  double get fatsPercent => total > 0 ? fats / total : 0.25;
  double get carbsPercent => total > 0 ? carbs / total : 0.25;
  double get fiberPercent => total > 0 ? fiber / total : 0.25;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Container(
          padding: EdgeInsets.only(top: 16, left: 19, bottom: 8, right: 19),
          decoration: BoxDecoration(
            color: Color(0xffFEF6FB).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
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
                title: "Fiber",
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
                dv: "${((fats / 65) * 100).toStringAsFixed(0)}%",
                sub: const [
                  SubNutrition(title: "Saturated fat", value: "0g", dv: "0%"),
                  SubNutrition(title: "Trans fat", value: "0g", dv: "0%"),
                ],
              ),

              nutritionItem(
                title: "Protein",
                value: "${protein.toStringAsFixed(1)}g",
                dv: "${((protein / 50) * 100).toStringAsFixed(0)}%",
              ),

              nutritionItem(
                title: "Total Carbohydrates",
                value: "${carbs.toStringAsFixed(1)}g",
                dv: "${((carbs / 300) * 100).toStringAsFixed(0)}%",
                sub: [
                  SubNutrition(
                    title: "Dietary Fiber",
                    value: "${fiber.toStringAsFixed(1)}g",
                    dv: "${((fiber / 25) * 100).toStringAsFixed(0)}%",
                  ),
                  const SubNutrition(title: "Sugar", value: "0g", dv: "0%"),
                ],
              ),

              nutritionItem(title: "Cholesterol", value: "0mg", dv: "0%"),
              nutritionItem(title: "Sodium", value: "0mg", dv: "0%"),
              nutritionItem(title: "Calcium", value: "0mg", dv: "0%"),
              nutritionItem(title: "Iron", value: "0mg", dv: "0%"),
              nutritionItem(title: "Potassium", value: "0mg", dv: "0%"),
              nutritionItem(title: "Vitamin C", value: "0mg", dv: "0%"),
            ],
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
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            color: Color(0xff530630),
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
