import 'package:docwellnesdoc/app/models/timeline_models.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/controllers/patient_timeline_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// What a patient actually logged on a given day - opened by tapping a
/// daily node on the dietician's timeline. Meal-linked tasks (see
/// GoalTask.linked) already carry their logged detail straight from
/// `milestone.tasks` (same MealLog-backed data the patient's own
/// MilestoneSheet shows), so this reads them directly instead of a
/// separate, potentially-diverging meals list. Weight/measurements have no
/// task of their own, so those still come from GET
/// /api/dietician/patients/:patientId/days/:date/logs - read-only, no
/// editing here.
class DayLogsSheet extends StatefulWidget {
  final PatientTimelineController controller;
  final Milestone milestone;
  final VoidCallback onNudge;

  const DayLogsSheet({
    super.key,
    required this.controller,
    required this.milestone,
    required this.onNudge,
  });

  @override
  State<DayLogsSheet> createState() => _DayLogsSheetState();
}

class _DayLogsSheetState extends State<DayLogsSheet> {
  static const _deep = Color(0xff530630);
  static const _maroon = Color(0xff851653);
  static const _muted = Color(0xff98A2AD);

  bool _loading = true;
  List<dynamic> _progress = [];

  DateTime get _date => widget.milestone.date;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.controller.service.getDayLogs(widget.controller.userId, _date);
    if (!mounted) return;
    setState(() {
      _progress = data?['progress'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.milestone.tasks;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffFCE7F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: DateFormat('EEEE, d MMM').format(_date),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _deep,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onNudge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _maroon,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          CustomText(
                            text: 'Nudge',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tasks.isNotEmpty) ...[
                const CustomText(
                  text: 'TASKS',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: _muted,
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final groups = TaskGroups.from(tasks);
                  return Column(
                    children: [
                      if (groups.mealTotal > 0) _groupCard('Log Meal', Icons.restaurant_menu, groups.mealComplete, groups.mealDone, groups.mealTotal, subRows: groups.mealTasks),
                      if (groups.waterTask != null)
                        _groupCard(
                          'Water Intake',
                          groups.waterTask!.icon,
                          groups.waterTask!.done,
                          null,
                          null,
                          progress: groups.waterTask!.progress,
                          progressLabel: groups.waterTask!.loggedNote,
                        ),
                      ...groups.otherTasks.map(_taskRow),
                    ],
                  );
                }),
                const SizedBox(height: 8),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _maroon)),
                )
              else ...[
                const CustomText(
                  text: 'WEIGHT / MEASUREMENTS',
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Color(0xff98A2AD),
                ),
                const SizedBox(height: 8),
                if (_progress.isEmpty)
                  const CustomText(
                    text: 'No weigh-in logged this day.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Color(0xff98A2AD),
                  )
                else
                  ..._progress.map((p) {
                    final entry = Map<String, dynamic>.from(p as Map);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.monitor_weight, size: 16, color: _maroon),
                          const SizedBox(width: 8),
                          CustomText(
                            text: entry['weight'] != null ? '${entry['weight']} kg' : 'Logged',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _deep,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskRow(GoalTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: task.done ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: task.done ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
      ),
      child: Row(
        children: [
          Icon(task.icon, size: 18, color: task.done ? const Color(0xff1F8A5B) : _maroon),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(text: task.title, fontWeight: FontWeight.w600, fontSize: 13, color: _deep),
          ),
          CustomText(
            text: task.linked
                ? (task.loggedNote ?? (task.done ? 'Logged' : 'Not logged'))
                : (task.done ? 'Done' : 'Not done'),
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: task.done ? const Color(0xff1F8A5B) : _muted,
          ),
        ],
      ),
    );
  }

  /// Read-only view of the "Log Meal"/"Water Intake" progress groups (see
  /// TaskGroups in timeline_models.dart) - no expand/collapse needed since
  /// the dietician never taps to check anything off; the sub-rows (meal
  /// serving-times, or nothing for Water Intake) are always visible so the
  /// dietician can see exactly what's missing before deciding to nudge.
  Widget _groupCard(
    String title,
    IconData icon,
    bool complete,
    int? done,
    int? total, {
    List<GoalTask>? subRows,
    double? progress,
    String? progressLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: complete ? const Color(0xffF0FBF6) : const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: complete ? const Color(0xffBEE8D4) : const Color(0xffFCE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: complete ? const Color(0xff1F8A5B) : _maroon),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(text: title, fontWeight: FontWeight.w600, fontSize: 13, color: _deep),
              ),
              CustomText(
                text: complete ? 'Complete' : (done != null ? '$done/$total' : (progressLabel ?? '')),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: complete ? const Color(0xff1F8A5B) : _muted,
              ),
            ],
          ),
          if (!complete && progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 5, color: const Color(0xffFCE7F6)),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: Container(height: 5, color: _maroon),
                  ),
                ],
              ),
            ),
          ],
          if (!complete && subRows != null && subRows.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...subRows.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        t.done ? Icons.check_circle : Icons.circle_outlined,
                        size: 13,
                        color: t.done ? const Color(0xff1F8A5B) : const Color(0xffE9C6DC),
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        text: t.title,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                        color: t.done ? _deep : _muted,
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
