import 'package:docwellnesdoc/app/modules/patients/widgets/food_card_widget.dart'
    show FoodInfoIndicator;
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';

class LogMealContainer extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int plannedCalories;
  final int caloriesConsumed;
  final int loggedServings;
  final bool isLogged;
  final num protein;
  final num fiber;
  final num carbs;
  final num fat;

  const LogMealContainer({
    super.key,
    required this.name,
    this.imageUrl,
    this.plannedCalories = 0,
    this.caloriesConsumed = 0,
    this.loggedServings = 0,
    this.isLogged = false,
    this.protein = 0,
    this.fiber = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  /// Drops a trailing ".0" (e.g. 5.0 -> "5") but keeps real decimals.
  String _formatGrams(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          border: cardBorder,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    text: name,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff384250),
                  ),
                ),
                SizedBox(width: 8),
                if (isLogged)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xffD1FAE5),
                      border: Border.all(color: Color(0xff34D399)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Color(0xff065F46),
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          text: 'Logged',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Color(0xff065F46),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xffFCE7F6),
                      border: Border.all(color: Color(0xffEF45B2)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: CustomText(
                      text: 'Not logged',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xff851653),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            CustomText(
              text: isLogged ? '$caloriesConsumed calorie' : '$plannedCalories calorie',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xff6C737F),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FoodInfoIndicator(
                  value: "${_formatGrams(protein)}g",
                  label: "Protein",
                  icon: 'assets/icons/diet1.png',
                ),
                FoodInfoIndicator(
                  value: "${_formatGrams(fiber)}g",
                  label: "Fiber",
                  icon: 'assets/icons/diet2.png',
                ),
                FoodInfoIndicator(
                  value: "${_formatGrams(carbs)}g",
                  label: "Carbs",
                  icon: 'assets/icons/diet3.png',
                ),
                FoodInfoIndicator(
                  value: "${_formatGrams(fat)}g",
                  label: "Fat",
                  icon: 'assets/icons/diet4.png',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
