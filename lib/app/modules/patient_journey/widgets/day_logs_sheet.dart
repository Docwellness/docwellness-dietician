import 'package:docwellnesdoc/app/modules/patient_journey/controllers/patient_timeline_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// What a patient actually logged on a given day - opened by tapping a node
/// on the dietician's timeline. Reads existing MealLog/Progress data (see
/// GET /api/dietician/patients/:patientId/days/:date/logs), not new
/// storage - a read-only view, no editing here.
class DayLogsSheet extends StatefulWidget {
  final PatientTimelineController controller;
  final DateTime date;
  final VoidCallback onNudge;

  const DayLogsSheet({
    super.key,
    required this.controller,
    required this.date,
    required this.onNudge,
  });

  @override
  State<DayLogsSheet> createState() => _DayLogsSheetState();
}

class _DayLogsSheetState extends State<DayLogsSheet> {
  static const _deep = Color(0xff530630);
  static const _maroon = Color(0xff851653);

  bool _loading = true;
  List<dynamic> _meals = [];
  List<dynamic> _progress = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.controller.service.getDayLogs(widget.controller.userId, widget.date);
    if (!mounted) return;
    setState(() {
      _meals = data?['meals'] as List? ?? [];
      _progress = data?['progress'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                    text: DateFormat('EEEE, d MMM').format(widget.date),
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _maroon)),
              )
            else ...[
              const CustomText(
                text: 'MEALS LOGGED',
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: Color(0xff98A2AD),
              ),
              const SizedBox(height: 8),
              if (_meals.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CustomText(
                    text: 'No meals logged this day.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Color(0xff98A2AD),
                  ),
                )
              else
                ..._meals.map((meal) {
                  final m = Map<String, dynamic>.from(meal as Map);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant_menu, size: 16, color: _maroon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomText(
                            text: m['mealType']?.toString() ?? 'Meal',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _deep,
                          ),
                        ),
                        if (m['caloriesConsumed'] != null)
                          CustomText(
                            text: '${m['caloriesConsumed']} kcal',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: const Color(0xff98A2AD),
                          ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
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
    );
  }
}
