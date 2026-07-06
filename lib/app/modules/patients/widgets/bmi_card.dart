
import 'package:docwellnesdoc/app/modules/patients/widgets/bmi_range_bar.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BmiContainer extends StatelessWidget {
  final int index;
  final double value;
  final String targetedWeight;
  final int? activityLevel;
  final List<String> healthConcerentList;
  final String? activityLevelText;

  const BmiContainer({
    super.key,
    required this.index,
    required this.value,
    required this.targetedWeight,
    required this.activityLevel,
    required this.healthConcerentList,
    this.activityLevelText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xffF9FAFB)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 5),
            blurRadius: 25,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Color(0x1B000000),
            offset: Offset(0, 1.14),
            blurRadius: 5.72,
            spreadRadius: -2.67,
          ),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 0.3),
            blurRadius: 1.51,
            spreadRadius: -1.33,
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 12, right: 12, top: 13.5, bottom: 17.5),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: CustomText(
                  text: 'Body Mass Index (BMI) $value',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff851653),
                  textAlign: TextAlign.center,
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: index == 0
                          ? 85
                          : index == 1
                          ? 120
                          : 112,
                      height: 24,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Color(0xffFDF2FA)
                            : index == 1
                            ? Color(0xff2D9CDB)
                            : Color(0xffF2C94C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: index == 0
                              ? Color(0xffFCE7F6)
                              : index == 1
                              ? Color(0xff2D9CDB)
                              : Color(0xffF2C94C),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/star.png',
                              height: 12,
                              width: 11.91,
                              color: index == 0
                                  ? Color(0xffEF45B2)
                                  : Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            SizedBox(width: 4),
                            CustomText(
                              text: index == 0
                                  ? 'NORMAL'
                                  : index == 1
                                  ? 'UNDERWEIGHT'
                                  : 'OVERWEIGHT',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: index == 0
                                  ? Color(0xffEF45B2)
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                fontSize: 13.2,
                color: Color(0xff4D5761),
              ),
              children: [
                const TextSpan(
                  text: 'High BMI leads to greater health risks. ',
                ),
                TextSpan(
                  text: 'Reference Link',
                  style: GoogleFonts.roboto(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          BmiRangeBar(bmiValue: value),
          SizedBox(height: 8),
          Image.asset('assets/icons/Divider.png', width: double.infinity),
          SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/weight_device.png',
                            height: 24,
                            fit: BoxFit.cover,
                            width: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Target Weight',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: targetedWeight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/Unwell.png',
                            height: 19,
                            fit: BoxFit.cover,
                            width: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Illness attention',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: healthConcerentList.join(", "),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/icons/Group.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Level',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                CustomText(
                                  text: activityLevel == null
                                      ? activityLevelText ?? ''
                                      : activityLevel == 0
                                      ? 'Sedentary'
                                      : activityLevel == 1
                                      ? 'Lightly Activity'
                                      : activityLevel == 2
                                      ? 'Moderately Activity'
                                      : 'Very Active',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xff384250),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                Flexible(
                  flex: 0,
                  child: Image.asset(
                    'assets/images/yoga_girl.png',
                    width: 120,
                    height: 87,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
