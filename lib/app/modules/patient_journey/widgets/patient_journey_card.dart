import 'package:docwellnesdoc/app/models/timeline_models.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/controllers/patient_timeline_controller.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/views/patient_timeline_screen.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/widgets/nudge_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dietician-facing Goal Journey summary card - inserted into
/// patient_profile_view.dart right after the Weekly Diet Plan section.
/// One GetBuilder-scoped PatientTimelineController per card (tag: userId),
/// since a dietician's session may view many different patients.
class PatientJourneyCard extends StatelessWidget {
  final String userId;
  final String patientName;

  const PatientJourneyCard({super.key, required this.userId, required this.patientName});

  static const _deep = Color(0xff530630);
  static const _maroon = Color(0xff851653);
  static const _border = Color(0xffFCE7F6);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PatientTimelineController>(
      init: PatientTimelineController(userId: userId, patientName: patientName),
      tag: userId,
      builder: (c) {
        return Obx(() {
          if (c.state.value == PatientTimelineUiState.loading ||
              c.state.value == PatientTimelineUiState.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _maroon)),
            );
          }
          // No active goal for this patient yet (e.g. no target weight on
          // file) - render nothing rather than an empty error box.
          if (c.state.value == PatientTimelineUiState.error || c.goal.value == null) {
            return const SizedBox.shrink();
          }

          final goal = c.goal.value!;
          final stats = c.stats.value;
          final dailyMilestones =
              c.milestones.where((m) => m.type == MilestoneType.daily).toList();
          final todayIndex = dailyMilestones.indexWhere((m) => m.status == MilestoneStatus.active);
          final recentWindow = _centeredWindow(dailyMilestones, todayIndex, 14);

          return GestureDetector(
            onTap: () => Get.to(
              () => const PatientTimelineScreen(),
              arguments: {'userId': userId, 'name': patientName},
            ),
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _deep.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CustomText(
                        text: 'GOAL JOURNEY',
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: Color(0xffC4547F),
                      ),
                      const Spacer(),
                      _riskBadge(c.riskLevel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: goal.title,
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                    color: const Color(0xff98A2AD),
                  ),
                  const SizedBox(height: 12),
                  if (recentWindow.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: recentWindow.map((m) {
                        return Tooltip(
                          message: '${m.title} · ${(m.adherence * 100).toInt()}%',
                          child: Container(
                            width: 10,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c.adherenceColor(m).withValues(alpha: 0.25 + m.adherence * 0.75),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (stats != null) ...[
                    const SizedBox(height: 6),
                    CustomText(
                      text: '${stats.daysElapsed} days completed · ${stats.daysToGo} days remaining',
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                      color: const Color(0xff98A2AD),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metric('Streak', '${stats?.streak ?? 0}d'),
                      const SizedBox(width: 18),
                      _metric('30d adherence', '${((stats?.adherence30d ?? 0) * 100).toInt()}%'),
                      const SizedBox(width: 18),
                      _metric('Now', '${goal.currentValue.toStringAsFixed(1)} kg'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openNudgeSheet(context, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _maroon,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_active, size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              CustomText(
                                text: 'Nudge',
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _riskBadge(String level) {
    final color = level == 'On track'
        ? const Color(0xff10B981)
        : level == 'Slipping'
            ? const Color(0xffF59E0B)
            : const Color(0xffDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          CustomText(text: level, fontWeight: FontWeight.w800, fontSize: 10.5, color: color),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: value, fontWeight: FontWeight.w900, fontSize: 15, color: _deep),
          CustomText(
            text: label,
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            color: const Color(0xff98A2AD),
          ),
        ],
      );

  void _openNudgeSheet(BuildContext context, PatientTimelineController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => NudgeSheet(controller: c),
    );
  }
}

/// Same centered-window logic as docwellness-user's journey_card.dart -
/// today's dot sits at the middle of the window as long as there's enough
/// goal left on both sides, sliding right only once fewer than half the
/// window's worth of future days remain.
List<Milestone> _centeredWindow(List<Milestone> days, int todayIndex, int windowSize) {
  if (days.isEmpty) return days;
  final lastIndex = days.length - 1;
  if (todayIndex < 0) {
    final start = (days.length - windowSize).clamp(0, days.length);
    return days.sublist(start);
  }

  final center = windowSize ~/ 2;
  int start = todayIndex - center;
  int end = start + windowSize - 1;
  if (end > lastIndex) {
    start -= (end - lastIndex);
  }
  if (start < 0) start = 0;
  final clampedEnd = (start + windowSize - 1).clamp(0, lastIndex);
  return days.sublist(start, clampedEnd + 1);
}
