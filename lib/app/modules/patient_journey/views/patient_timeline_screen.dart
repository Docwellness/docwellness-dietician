import 'package:docwellnesdoc/app/models/timeline_models.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/controllers/patient_timeline_controller.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/widgets/day_logs_sheet.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/widgets/nudge_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Detail timeline screen - the same single journey line as the patient
/// app's GoalTimelineScreen, but nodes are colored by adherence heat
/// (PatientTimelineController.adherenceColor) instead of plain done/missed,
/// and tapping a daily node opens DayLogsSheet (what the patient actually
/// logged) instead of a task-checkin sheet - the dietician is view-only
/// here, never checking off tasks on the patient's behalf.
class PatientTimelineScreen extends StatelessWidget {
  const PatientTimelineScreen({super.key});

  static const _deep = Color(0xff530630);
  static const _maroon = Color(0xff851653);
  static const _nodeSpacing = 56.0;
  static const _dotAreaHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userId'] as String? ?? '';
    final name = args['name'] as String? ?? 'Patient';

    // Same tag as PatientJourneyCard (just `userId`, not a separate
    // '${userId}_screen' namespace) - GetBuilder reuses whatever controller
    // is already registered under that tag, so if the card already loaded
    // this patient's timeline, opening the screen shows that data
    // immediately instead of spinning up a brand-new controller and
    // cold-fetching from scratch every single tap (the same "why does this
    // take forever to open" symptom fixed in the patient app's
    // GoalTimelineScreen, just caused here by a tag mismatch instead of a
    // redundant non-silent load()).
    return GetBuilder<PatientTimelineController>(
      init: PatientTimelineController(userId: userId, patientName: name),
      tag: userId,
      builder: (c) {
        return Scaffold(
          backgroundColor: const Color(0xffFEF6FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: _deep),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(text: c.patientName, fontWeight: FontWeight.w800, fontSize: 16, color: _deep),
                Obx(
                  () => CustomText(
                    text: 'Goal: ${c.goal.value?.title ?? '—'} · ${c.riskLevel}',
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: const Color(0xff98A2AD),
                  ),
                ),
              ],
            ),
          ),
          body: Obx(() {
            if (c.state.value != PatientTimelineUiState.success) {
              return c.state.value == PatientTimelineUiState.error
                  ? const Center(
                      child: CustomText(
                        text: 'No active goal for this patient yet.',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xff4D5761),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator(color: _maroon));
            }

            return ListView(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: c.milestones.length * _nodeSpacing,
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          // Fixed-height dot slot (see _dotAreaHeight) so
                          // every node's circle centers on the same
                          // baseline this line is drawn through, regardless
                          // of its own diameter (16px daily vs 32px
                          // end-goal) - same fix as docwellness-user's
                          // journey_line_painter.dart/milestone_node.dart.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: _dotAreaHeight,
                            child: CustomPaint(
                              painter: _AdherenceLinePainter(
                                statuses: c.milestones.map((m) => m.status).toList(),
                                centerY: _dotAreaHeight / 2,
                                nodeSpacing: _nodeSpacing,
                              ),
                            ),
                          ),
                          Row(
                            children: c.milestones.map((m) {
                              return GestureDetector(
                                onTap: () {
                                  if (m.type == MilestoneType.daily) {
                                    _openDayLogs(context, c, m);
                                  }
                                },
                                child: SizedBox(
                                  width: _nodeSpacing,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: _dotAreaHeight,
                                        child: Center(
                                          child: Container(
                                            width: m.type == MilestoneType.endGoal ? 32 : 16,
                                            height: m.type == MilestoneType.endGoal ? 32 : 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: c.adherenceColor(m),
                                            ),
                                            child: m.type == MilestoneType.endGoal
                                                ? const Center(
                                                    child: Text('🏆', style: TextStyle(fontSize: 14)))
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      CustomText(
                                        text: m.title,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 9.5,
                                        color: const Color(0xff98A2AD),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      _LegendDot(color: Color(0xff10B981), label: '≥70%'),
                      SizedBox(width: 14),
                      _LegendDot(color: Color(0xffF59E0B), label: '40–69%'),
                      SizedBox(width: 14),
                      _LegendDot(color: Color(0xffDC2626), label: '<40%'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openNudge(context, c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _maroon,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_active, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          CustomText(
                            text: 'Send a nudge',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          }),
        );
      },
    );
  }

  void _openDayLogs(BuildContext context, PatientTimelineController c, Milestone m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      // Capped below full height (same fix as the patient app's
      // MilestoneSheet) so a day with many tasks doesn't stretch this sheet
      // flush to the top of the screen with no margin.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => DayLogsSheet(
          controller: c,
          milestone: m,
          scrollController: scrollController,
          onNudge: () {
            Navigator.pop(context);
            _openNudge(context, c, milestoneId: m.id);
          },
        ),
      ),
    );
  }

  void _openNudge(BuildContext context, PatientTimelineController c, {String? milestoneId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => NudgeSheet(controller: c, milestoneId: milestoneId),
    );
  }
}

/// Connects each pair of adjacent nodes with a solid adherence-colored
/// segment, except the final one (leading into the end-goal trophy), which
/// is always dashed/amber - the same "grace period" the backend's daily
/// goal-nudge sweep watches (controllers/internal/goalNudgeController.js) -
/// mirrors docwellness-user's journey_line_painter.dart.
class _AdherenceLinePainter extends CustomPainter {
  final List<MilestoneStatus> statuses;
  final double centerY;
  final double nodeSpacing;

  _AdherenceLinePainter({required this.statuses, required this.centerY, required this.nodeSpacing});

  static const _doneColor = Color(0xff10B981);
  static const _baseColor = Color(0xffFCE7F6);
  static const _nudgeZoneColor = Color(0xffF59E0B);
  static const _dashWidth = 5.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (statuses.length < 2) return;

    final basePaint = Paint()
      ..color = _baseColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final donePaint = Paint()
      ..color = _doneColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final nudgePaint = Paint()
      ..color = _nudgeZoneColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < statuses.length - 1; i++) {
      final startX = nodeSpacing * i + nodeSpacing / 2;
      final endX = nodeSpacing * (i + 1) + nodeSpacing / 2;
      if (i == statuses.length - 2) {
        _drawDashedLine(canvas, Offset(startX, centerY), Offset(endX, centerY), nudgePaint);
        continue;
      }
      final isDoneSegment = statuses[i] == MilestoneStatus.completed;
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(endX, centerY),
        isDoneSegment ? donePaint : basePaint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    double drawn = 0;
    while (drawn < totalLength) {
      final segmentEnd = (drawn + _dashWidth).clamp(0, totalLength).toDouble();
      canvas.drawLine(start + direction * drawn, start + direction * segmentEnd, paint);
      drawn += _dashWidth + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceLinePainter oldDelegate) =>
      oldDelegate.statuses != statuses || oldDelegate.centerY != centerY;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        CustomText(text: label, fontWeight: FontWeight.w500, fontSize: 10.5, color: const Color(0xff98A2AD)),
      ],
    );
  }
}
