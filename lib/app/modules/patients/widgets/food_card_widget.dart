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
  });

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
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: name,

                      color: Color(0xff384250),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
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
                            text: grams,

                            color: Color(0xff851653),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 5),
                        CustomText(
                          text: "$calorie calorie",

                          fontWeight: FontWeight.w400,
                          color: Color(0xff6C737F),
                          fontSize: 12,
                        ),
                      ],
                    ),
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

          // Reusable bottom indicators
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
