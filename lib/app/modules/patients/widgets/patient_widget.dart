import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/modules/patients/views/patient_profile_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PatientWidget extends StatelessWidget {
  final String? patientId;
  final String fullName;
  final String? avatarUrl;
  final int? streakDays;
  final String? trendText;
  final double? progressFromKg;
  final double? progressToKg;
  final double? adherencePercent;
  final double? bmiValue;
  final bool isActive;

  const PatientWidget({
    super.key,
    this.patientId,
    required this.fullName,
    this.avatarUrl,
    this.streakDays,
    this.trendText,
    this.progressFromKg,
    this.progressToKg,
    this.adherencePercent,
    this.bmiValue,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (patientId != null) {
          Get.to(() => PatientProfileView(patientId: patientId!));
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

                // Name + Streak + Trend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              text: fullName,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color(0xff111927),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffDC2626),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const CustomText(
                                text: "Deactivated",
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (isActive && streakDays != null && streakDays! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xff851653),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: CustomText(
                                text: "$streakDays days Streak",
                                color: Color(0xffFEF6FB),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      CustomText(
                        text: trendText ?? "No trend data",
                        color: Color(0xff6C737F),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ----------------- INDICATORS -----------------
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 1),
                  _statItem(
                    "Progress",
                    progressFromKg != null && progressToKg != null
                        ? "${progressFromKg!.toStringAsFixed(0)} kg > ${progressToKg!.toStringAsFixed(0)} Kg"
                        : "-- kg > -- kg",
                    progressFromKg != null &&
                            progressToKg != null &&
                            progressFromKg! > 0
                        ? ((progressFromKg! - progressToKg!) / progressFromKg!)
                              .clamp(0.0, 1.0)
                        : 0.0,
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    "Adherence",
                    adherencePercent != null
                        ? "${adherencePercent!.toStringAsFixed(0)}% logged"
                        : "--% logged",
                    (adherencePercent ?? 0) / 100,
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    "BMI",
                    bmiValue != null && bmiValue! > 0
                        ? bmiValue!.toStringAsFixed(1)
                        : "--",
                    bmiValue != null && bmiValue! > 0
                        ? (bmiValue! / 40).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Indicator Item -----------------
  Widget _statItem(String title, String value, double percent) {
    return SizedBox(
      width: 130,
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
