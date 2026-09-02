import 'package:docwellnesdoc/app/modules/exercises/controllers/exercises_controller.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _DraftEntry {
  final Exercise exercise;
  final int? durationMinutes;
  final int? sets;
  final int? reps;

  _DraftEntry({required this.exercise, this.durationMinutes, this.sets, this.reps});

  Map<String, dynamic> toPayload(String dayGroup) => {
        'exerciseId': exercise.id,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        'dayGroup': dayGroup,
      };
}

/// Edits one day-group's exercises directly from the tile that shows them
/// (see patient_profile_view.dart's Exercise Plan cards) - replaces the
/// separate "Edit Exercise Plan" button/full SelectExerciseSheet flow, which
/// forced a trip through all 4 day-groups just to change one.
class EditExerciseDayGroupSheet extends StatefulWidget {
  final String patientId;
  final String dayGroup;
  final String dayGroupLabel;
  final List<Map<String, dynamic>> initialEntries;

  const EditExerciseDayGroupSheet({
    super.key,
    required this.patientId,
    required this.dayGroup,
    required this.dayGroupLabel,
    required this.initialEntries,
  });

  @override
  State<EditExerciseDayGroupSheet> createState() => _EditExerciseDayGroupSheetState();
}

class _EditExerciseDayGroupSheetState extends State<EditExerciseDayGroupSheet> {
  static const _accent = Color(0xff851653);

  final ExercisesController exercisesController = Get.isRegistered<ExercisesController>()
      ? Get.find<ExercisesController>()
      : Get.put(ExercisesController());
  final PatientsController patientsController = Get.find<PatientsController>();

  late List<_DraftEntry> _entries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialEntries.map((e) {
      final exerciseField = e['exerciseId'];
      final exercise = exerciseField is Map
          ? Exercise.fromJson(Map<String, dynamic>.from(exerciseField))
          : Exercise(id: exerciseField?.toString() ?? '', name: 'Exercise', category: 'Other', met: 0);
      return _DraftEntry(
        exercise: exercise,
        durationMinutes: (e['durationMinutes'] as num?)?.toInt(),
        sets: (e['sets'] as num?)?.toInt(),
        reps: (e['reps'] as num?)?.toInt(),
      );
    }).toList();
  }

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
                title: CustomText(
                  text: exercise.name,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xff1F2A37),
                ),
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
        title: CustomText(
          text: exercise.name,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: const Color(0xff530630),
        ),
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
                _entries.add(
                  _DraftEntry(
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
    durationController.dispose();
    setsController.dispose();
    repsController.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await patientsController.saveExerciseDayGroupEntries(
      widget.patientId,
      widget.dayGroup,
      _entries.map((e) => e.toPayload(widget.dayGroup)).toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Get.back();
      showAppToast(
        Get.overlayContext!,
        message: '${widget.dayGroupLabel} exercises saved',
        type: AppToastType.success,
      );
    } else {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not save - please try again',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: widget.dayGroupLabel,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: const Color(0xff530630),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _entries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CustomText(
                          text: 'No exercises assigned for this day yet.',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xff6C737F),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final parts = <String>[
                            if (entry.durationMinutes != null)
                              entry.sets != null ? '${entry.durationMinutes} min/set' : '${entry.durationMinutes} min',
                            if (entry.sets != null) '${entry.sets} sets',
                            if (entry.reps != null) '${entry.reps} reps',
                          ];
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
                                      CustomText(
                                        text: entry.exercise.name,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: const Color(0xff1F2A37),
                                      ),
                                      if (parts.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        CustomText(
                                          text: parts.join(' • '),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: const Color(0xff6C737F),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _entries.removeAt(index)),
                                  child: const Icon(Icons.close, size: 20, color: Color(0xff9DA4AE)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
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
                text: 'Save',
                isOutline: false,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
