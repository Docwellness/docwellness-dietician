import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PastPatientWidget extends StatelessWidget {
  final String? patientId;
  final String fullName;
  final String? avatarUrl;
  final double? finalWeight;
  final double? totalKgLost;
  final double? bmiBefore;
  final double? bmiAfter;
  final String? completedOn;

  const PastPatientWidget({
    super.key,
    this.patientId,
    required this.fullName,
    this.avatarUrl,
    this.finalWeight,
    this.totalKgLost,
    this.bmiBefore,
    this.bmiAfter,
    this.completedOn,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (patientId != null) {
          final controller = Get.find<PatientsController>();
          controller.getPatientProfile(patientId!);
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
                // Avatar + completed badge
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
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Name + Completed badge
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: CustomText(
                              text: "Completed",
                              color: Colors.green.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      CustomText(
                        text: "Completed on: ${_formatDate(completedOn)}",
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
                    "Final Weight",
                    finalWeight != null
                        ? "${finalWeight!.toStringAsFixed(1)} kg"
                        : "-- kg",
                    0.7,
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    "Total Lost",
                    totalKgLost != null
                        ? "${totalKgLost!.toStringAsFixed(1)} kg"
                        : "-- kg",
                    totalKgLost != null
                        ? (totalKgLost! / 20).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                  const SizedBox(width: 10),
                  _statItem(
                    "BMI Change",
                    bmiBefore != null && bmiAfter != null
                        ? "${bmiBefore!.toStringAsFixed(1)} → ${bmiAfter!.toStringAsFixed(1)}"
                        : "-- → --",
                    bmiAfter != null ? (bmiAfter! / 40).clamp(0.0, 1.0) : 0.0,
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
              color: Colors.green,
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
