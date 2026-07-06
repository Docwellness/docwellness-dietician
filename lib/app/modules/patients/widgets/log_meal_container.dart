import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class LogMealContainer extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int plannedCalories;
  final int caloriesConsumed;
  final int loggedServings;
  final bool isLogged;

  const LogMealContainer({
    super.key,
    required this.name,
    this.imageUrl,
    this.plannedCalories = 0,
    this.caloriesConsumed = 0,
    this.loggedServings = 0,
    this.isLogged = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          border: Border.all(color: Color(0xffFDF2FA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage(
                          'assets/demos/f9671a09876137e99a3c3426fef073468230cd4a.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: name,
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff384250),
                  ),
                  Wrap(
                    children: [
                      if (isLogged)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: Color(0xffD1FAE5),
                            border: Border.all(color: Color(0xff34D399)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: CustomText(
                            text: 'Logged ($loggedServings servings)',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xff065F46),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: Color(0xffFCE7F6),
                            border: Border.all(color: Color(0xffEF45B2)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: CustomText(
                            text: 'Not logged',
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xff851653),
                          ),
                        ),
                      SizedBox(width: 4),
                      CustomText(
                        text: isLogged
                            ? '$caloriesConsumed / $plannedCalories kcal'
                            : '$plannedCalories kcal',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xff6C737F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
