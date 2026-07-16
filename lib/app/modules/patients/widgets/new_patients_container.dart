import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewPatientsContainer extends StatelessWidget {
  final String? patientId;
  final String fullName;
  final String? avatarUrl;
  final double? weight;
  final double? bmi;
  final double? bmr;
  final double? tdee;
  final String? statusLabel;
  final String? membershipPlan;

  const NewPatientsContainer({
    super.key,
    this.patientId,
    required this.fullName,
    this.avatarUrl,
    this.weight,
    this.bmi,
    this.bmr,
    this.tdee,
    this.statusLabel,
    this.membershipPlan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (patientId != null) {
          Get.toNamed('/patient-profile/${patientId!}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffFFF5FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------- TOP SECTION -----------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + pink dot
                Stack(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xffF3F4F6),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: avatarUrl != null && avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Color(0xffF3F4F6),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xff851653),
                                      ),
                                    ),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Color(0xffF3F4F6),
                                      child: Icon(
                                        Icons.person,
                                        color: Color(0xff851653),
                                      ),
                                    ),
                              )
                            : const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xffF3F4F6),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xff851653),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 3,
                      right: 3,
                      child: Container(
                        height: 11,
                        width: 11,
                        decoration: BoxDecoration(
                          color: Color(0xffDE2493),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Name + Status + Weight
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              children: [
                                CustomText(
                                  text: fullName,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xff111927),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(width: 5),
                                if (statusLabel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xffFDF2FA),
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                        color: Color(0xff851653),
                                      ),
                                    ),
                                    child: CustomText(
                                      text: statusLabel!.toUpperCase(),
                                      color: Color(0xff851653),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (membershipPlan != null &&
                                    membershipPlan!.isNotEmpty) ...[
                                  SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF3F4F6),
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                        color: const Color(0xffD1D5DB),
                                      ),
                                    ),
                                    child: CustomText(
                                      text: membershipPlan!,
                                      color: const Color(0xff4D5761),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          CustomText(
                            text: weight != null
                                ? '${weight!.toStringAsFixed(0)} KG'
                                : '-- KG',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Color(0xff111927),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      CustomText(
                        text: "New patient - awaiting consultation",
                        color: Color(0xff6C737F),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------- INDICATORS -----------------
            Row(
              children: [
                _statItem(
                  "BMI",
                  bmi?.toStringAsFixed(1) ?? "--",
                  bmi != null ? (bmi! / 40).clamp(0.0, 1.0) : 0.0,
                ),
                const SizedBox(width: 10),
                _statItem(
                  "BMR",
                  bmr?.toStringAsFixed(0) ?? "--",
                  bmr != null ? (bmr! / 2500).clamp(0.0, 1.0) : 0.0,
                ),
                const SizedBox(width: 10),
                _statItem(
                  "TDEE",
                  tdee?.toStringAsFixed(0) ?? "--",
                  tdee != null ? (tdee! / 3000).clamp(0.0, 1.0) : 0.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Indicator Item -----------------
  Widget _statItem(String title, String value, double percent) {
    return Expanded(
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 2.5,
              color: Color(0xff851653),
              backgroundColor: Color(0xffFCE7F6),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 12,
                  color: Color(0xff6C737F),
                  fontWeight: FontWeight.w400,
                ),
                CustomText(
                  text: value,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 14,
                  color: Color(0xff384250),
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
