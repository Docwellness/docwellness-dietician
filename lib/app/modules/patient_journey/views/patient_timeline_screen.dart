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

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userId'] as String? ?? '';
    final name = args['name'] as String? ?? 'Patient';

    return GetBuilder<PatientTimelineController>(
      init: PatientTimelineController(userId: userId, patientName: name),
      tag: '${userId}_screen',
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
                    child: Row(
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
                                Container(
                                  width: m.type == MilestoneType.endGoal ? 32 : 16,
                                  height: m.type == MilestoneType.endGoal ? 32 : 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.adherenceColor(m),
                                  ),
                                  child: m.type == MilestoneType.endGoal
                                      ? const Center(child: Text('🏆', style: TextStyle(fontSize: 14)))
                                      : null,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DayLogsSheet(
        controller: c,
        date: m.date,
        onNudge: () {
          Navigator.pop(context);
          _openNudge(context, c, milestoneId: m.id);
        },
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
