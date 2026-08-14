import 'package:docwellnesdoc/app/modules/exercises/controllers/exercises_controller.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/modules/exercises/services/exercise_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One assigned entry, held in local draft state until "Save Plan" is
/// tapped - genuinely new UI (no diet-plan equivalent to copy: unlike
/// select_diet_sheet.dart, which reviews/toggles an AI-drafted selection,
/// here the dietician builds the list by hand from the Exercise catalog).
class _AssignedEntry {
  final Exercise exercise;
  // All three of duration/sets/reps are optional - some exercises are
  // better prescribed by sets/reps alone (e.g. "3x15 push-ups"), others by
  // duration alone (e.g. "10 min jump rope"). When both duration and sets
  // are set, duration is PER SET (total = duration * sets) - see
  // ExercisePlan.js's comment. The patient's own actual duration at log
  // time takes priority when given; this planned figure (or the exercise
  // catalog's secondsPerRep) is only a fallback estimate when they leave
  // it blank - see submitExerciseLog.
  final int? durationMinutes;
  final int? sets;
  final int? reps;

  _AssignedEntry({
    required this.exercise,
    this.durationMinutes,
    this.sets,
    this.reps,
  });
}

const List<String> _dayGroups = ['Monday', 'Tuesday', 'Wednesday', 'Thursday'];

class SelectExerciseSheet extends StatefulWidget {
  final String patientId;
  const SelectExerciseSheet({super.key, required this.patientId});

  @override
  State<SelectExerciseSheet> createState() => _SelectExerciseSheetState();
}

class _SelectExerciseSheetState extends State<SelectExerciseSheet> {
  final ExercisesController exercisesController = Get.isRegistered<ExercisesController>()
      ? Get.find<ExercisesController>()
      : Get.put(ExercisesController());
  final ExerciseService _exerciseService = ExerciseService();

  static const _accent = Color(0xff851653);

  String _selectedDayGroup = _dayGroups.first;
  final Map<String, List<_AssignedEntry>> _byDayGroup = {
    for (final g in _dayGroups) g: [],
  };
  bool isSaving = false;

  Future<void> _openExercisePicker() async {
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Obx(
          () => ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: exercisesController.exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercisesController.exercises[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center, color: _accent),
                title: CustomText(text: exercise.name, fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xff1F2A37)),
                subtitle: CustomText(
                  text: '${exercise.category} • MET ${exercise.met}',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: const Color(0xff6C737F),
                ),
                onTap: () => Navigator.pop(context, exercise),
              );
            },
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      _openDurationDialog(picked);
    }
  }

  Future<void> _openDurationDialog(Exercise exercise) async {
    final durationController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(text: exercise.name, fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xff530630)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomField(
              controller: durationController,
              lable: 'Duration per set, in minutes (optional)',
              hintText: 'Total duration if Sets is left blank',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomField(controller: setsController, lable: 'Sets (optional)', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CustomField(controller: repsController, lable: 'Reps (optional)', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _byDayGroup[_selectedDayGroup]!.add(
                  _AssignedEntry(
                    exercise: exercise,
                    durationMinutes: int.tryParse(durationController.text.trim()),
                    sets: int.tryParse(setsController.text.trim()),
                    reps: int.tryParse(repsController.text.trim()),
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700, color: _accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final dailyExercises = <Map<String, dynamic>>[];
    _byDayGroup.forEach((dayGroup, entries) {
      for (final entry in entries) {
        dailyExercises.add({
          'exerciseId': entry.exercise.id,
          if (entry.durationMinutes != null) 'durationMinutes': entry.durationMinutes,
          if (entry.sets != null) 'sets': entry.sets,
          if (entry.reps != null) 'reps': entry.reps,
          'dayGroup': dayGroup,
        });
      }
    });

    if (dailyExercises.isEmpty) {
      Get.snackbar('Nothing to save', 'Assign at least one exercise first', backgroundColor: Colors.white);
      return;
    }

    setState(() => isSaving = true);
    final result = await _exerciseService.upsertExercisePlan(
      patientId: widget.patientId,
      dailyExercises: dailyExercises,
    );
    bool activated = false;
    if (result != null && result['_id'] != null) {
      activated = await _exerciseService.activateExercisePlan(
        patientId: widget.patientId,
        exercisePlanId: result['_id'].toString(),
      );
    }
    setState(() => isSaving = false);

    if (result != null) {
      Get.back();
      Get.snackbar(
        'Saved',
        activated ? 'Exercise plan saved and activated' : 'Exercise plan saved',
        backgroundColor: Colors.white,
      );
    } else {
      Get.snackbar('Failed', 'Could not save the exercise plan. Please try again.', backgroundColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesForDay = _byDayGroup[_selectedDayGroup]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        title: const CustomText(
          text: 'Assign Exercises',
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: _dayGroups.map((g) {
                final isSelected = g == _selectedDayGroup;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDayGroup = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _accent : const Color(0xffE5E7EB)),
                    ),
                    child: CustomText(
                      text: g,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isSelected ? Colors.white : const Color(0xff1F2A37),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: entriesForDay.isEmpty
                ? Center(
                    child: CustomText(
                      text: 'No exercises assigned for $_selectedDayGroup yet',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xff6C737F),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entriesForDay.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entriesForDay[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(12),
                          border: cardBorder,
                          boxShadow: cardShadow,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(text: entry.exercise.name, fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xff1F2A37)),
                                  CustomText(
                                    text: (() {
                                      final parts = [
                                        if (entry.durationMinutes != null)
                                          entry.sets != null ? '${entry.durationMinutes} min/set' : '${entry.durationMinutes} min',
                                        if (entry.sets != null) '${entry.sets} sets',
                                        if (entry.reps != null) '${entry.reps} reps',
                                      ];
                                      return parts.isEmpty ? 'No duration/sets/reps set' : parts.join(' • ');
                                    })(),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: const Color(0xff6C737F),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => entriesForDay.removeAt(index)),
                              child: const Icon(Icons.close, size: 20, color: Color(0xff9DA4AE)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _openExercisePicker,
                  icon: const Icon(Icons.add, color: _accent),
                  label: const Text('Add Exercise', style: TextStyle(color: _accent)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: _accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  onTap: _save,
                  text: 'Save Plan',
                  isOutline: false,
                  isLoading: isSaving,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
