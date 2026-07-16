import 'package:cached_network_image/cached_network_image.dart';
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
  final bool isActive;
  final String? status;
  final String? membershipPlan;

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
    this.isActive = true,
    this.status,
    this.membershipPlan,
  });

  // Same semantic palette as the dashboard's patient-request badge
  // (patient_request_container.dart) and the profile screen's payment chip
  // (patient_profile_view.dart) - kept identical so "Partially Paid" means
  // the same color everywhere in the app.
  Widget? _paymentStatusChip() {
    late final String label;
    late final Color bg;
    late final Color border;
    late final Color text;
    switch (status) {
      case 'Paid':
        label = 'PAID';
        bg = const Color(0xffD1FAE5);
        border = const Color(0xff10B981);
        text = const Color(0xff059669);
        break;
      case 'PartiallyPaid':
        label = 'PARTIALLY PAID';
        bg = const Color(0xffFFEDD5);
        border = const Color(0xffFB923C);
        text = const Color(0xffC2410C);
        break;
      case 'PaymentSubmitted':
        // Renewal/balance payment under review - the plan itself is still
        // active, this just flags there's a pending review to action.
        label = 'UNDER REVIEW';
        bg = const Color(0xffFEF3C7);
        border = const Color(0xffF59E0B);
        text = const Color(0xffD97706);
        break;
      default:
        return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: border, width: 1.2),
      ),
      child: CustomText(
        text: label,
        color: text,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Left-edge triage signal so a dietician can scan the whole list without
  // reading every card: red = needs attention now, amber = keep an eye on
  // it, green = on track. Deactivated patients get a neutral grey since
  // that's a different state, not a risk signal.
  Color _accentColor() {
    if (!isActive) return const Color(0xff9CA3AF);
    final adherence = adherencePercent ?? 100;
    final needsAttention =
        status == 'PartiallyPaid' || status == 'PaymentSubmitted';
    if (adherence < 40) return const Color(0xffDC2626);
    if (adherence < 70 || needsAttention) return const Color(0xffF59E0B);
    return const Color(0xff10B981);
  }

  String _progressSummary() {
    final trend = trendText ?? 'No trend data';
    if (progressFromKg != null && progressToKg != null) {
      return '$trend  ·  ${progressFromKg!.toStringAsFixed(1)}kg → ${progressToKg!.toStringAsFixed(1)}kg';
    }
    return trend;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();

    return GestureDetector(
      onTap: () {
        if (patientId != null) {
          Get.toNamed('/patient-profile/${patientId!}');
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              color: const Color(0xffFFF5FA),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Name + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: fullName,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color(0xff111927),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (_paymentStatusChip() != null)
                                  _paymentStatusChip()!,
                                if (membershipPlan != null &&
                                    membershipPlan!.isNotEmpty)
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
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                      color: const Color(0xff4D5761),
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
                                if (isActive &&
                                    streakDays != null &&
                                    streakDays! > 0)
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
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ----------------- ADHERENCE BAR -----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: "Adherence",
                        fontSize: 12,
                        color: Color(0xff6C737F),
                        fontWeight: FontWeight.w400,
                      ),
                      CustomText(
                        text: adherencePercent != null
                            ? "${adherencePercent!.toStringAsFixed(0)}%"
                            : "--%",
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ((adherencePercent ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: const Color(0xffFCE7F6),
                      color: accent,
                    ),
                  ),

                  const SizedBox(height: 10),

                  CustomText(
                    text: _progressSummary(),
                    color: Color(0xff6C737F),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
