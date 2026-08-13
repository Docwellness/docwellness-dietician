import 'package:docwellnesdoc/app/modules/exercises/controllers/exercises_controller.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Create exercise" form - mirrors add_receipes.dart's AI-drafted-then-
/// reviewed flow: the dietician enters a name (+ optional category hint),
/// taps "Generate with AI" to fill category/MET/description/instructions/
/// equipment/muscle groups, reviews and edits any field, then saves.
/// videoUrl stays manual (paste a demo link) - see the backend's
/// generateExercisePreview doc comment for why AI doesn't touch it.
class AddExerciseView extends StatefulWidget {
  const AddExerciseView({super.key});

  @override
  State<AddExerciseView> createState() => _AddExerciseViewState();
}

class _AddExerciseViewState extends State<AddExerciseView> {
  final ExercisesController controller = Get.find<ExercisesController>();

  final nameController = TextEditingController();
  final metController = TextEditingController();
  final secondsPerRepController = TextEditingController();
  final descriptionController = TextEditingController();
  final instructionsController = TextEditingController();
  final equipmentController = TextEditingController();
  final muscleGroupsController = TextEditingController();
  final videoUrlController = TextEditingController();

  String selectedCategory = exerciseCategories.first;
  String selectedDifficulty = exerciseDifficultyLevels.first;
  bool isSaving = false;
  bool isGenerating = false;
  int? referenceCaloriesBurned;
  int referenceDurationMinutes = 30;

  // Same 3 languages RecipeLanguageService supports on the patient app -
  // English is always included implicitly (it's the base content itself,
  // not a "translation"), so it isn't in this toggleable set.
  static const _translatableLanguages = ['Hindi', 'Marathi'];
  final Set<String> selectedLanguages = {};
  Map<String, dynamic> translations = {};

  static const _headerColor = Color(0xffFDF2FA);
  static const _accent = Color(0xff851653);

  Future<void> _generateWithAI() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Missing info', 'Enter an exercise name first', backgroundColor: Colors.white);
      return;
    }

    setState(() => isGenerating = true);
    final preview = await controller.generateExercisePreview(
      name: name,
      category: selectedCategory,
      languages: ['English', ...selectedLanguages],
    );
    setState(() => isGenerating = false);

    if (preview == null) {
      Get.snackbar('Failed', 'Could not generate this exercise. Please try again.', backgroundColor: Colors.white);
      return;
    }

    final ex = preview.exercise;
    setState(() {
      nameController.text = ex.name;
      selectedCategory = exerciseCategories.contains(ex.category) ? ex.category : selectedCategory;
      selectedDifficulty = exerciseDifficultyLevels.contains(ex.difficultyLevel) ? ex.difficultyLevel : selectedDifficulty;
      metController.text = ex.met > 0 ? ex.met.toString() : metController.text;
      secondsPerRepController.text = ex.secondsPerRep != null ? ex.secondsPerRep.toString() : secondsPerRepController.text;
      descriptionController.text = ex.description;
      instructionsController.text = ex.instructions.join(', ');
      equipmentController.text = ex.equipment.join(', ');
      muscleGroupsController.text = ex.targetMuscleGroups.join(', ');
      referenceCaloriesBurned = preview.referenceCaloriesBurned;
      referenceDurationMinutes = preview.referenceDurationMinutes;
      translations = ex.translations;
    });
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final met = double.tryParse(metController.text.trim());
    final secondsPerRep = double.tryParse(secondsPerRepController.text.trim());

    if (name.isEmpty || met == null || met <= 0) {
      Get.snackbar(
        'Missing info',
        'Name and a valid MET value are required',
        backgroundColor: Colors.white,
      );
      return;
    }

    setState(() => isSaving = true);
    final created = await controller.createExercise(
      Exercise(
        id: '',
        name: name,
        category: selectedCategory,
        met: met,
        secondsPerRep: secondsPerRep,
        difficultyLevel: selectedDifficulty,
        description: descriptionController.text.trim(),
        videoUrl: videoUrlController.text.trim(),
        instructions: instructionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        equipment: equipmentController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        targetMuscleGroups: muscleGroupsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        language: ['English', ...selectedLanguages],
        translations: translations,
      ),
    );
    setState(() => isSaving = false);

    if (created != null) {
      Get.back();
    } else {
      Get.snackbar(
        'Failed',
        'Could not save the exercise. Please try again.',
        backgroundColor: Colors.white,
      );
    }
  }

  Widget _chipRow(List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _accent : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _accent : const Color(0xffE5E7EB)),
            ),
            child: CustomText(
              text: option,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: isSelected ? Colors.white : const Color(0xff1F2A37),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        title: CustomText(
          text: 'Add Exercise',
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomField(controller: nameController, lable: 'Exercise Name'),
            const SizedBox(height: 16),
            CustomText(text: 'Category', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xff1F2A37)),
            const SizedBox(height: 8),
            _chipRow(exerciseCategories, selectedCategory, (v) => setState(() => selectedCategory = v)),
            const SizedBox(height: 16),
            CustomText(
              text: 'Also translate to (optional)',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xff1F2A37),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _translatableLanguages.map((lang) {
                final isSelected = selectedLanguages.contains(lang);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      selectedLanguages.remove(lang);
                    } else {
                      selectedLanguages.add(lang);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _accent : const Color(0xffE5E7EB)),
                    ),
                    child: CustomText(
                      text: lang,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isSelected ? Colors.white : const Color(0xff1F2A37),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            CustomButton(
              onTap: isGenerating ? () {} : _generateWithAI,
              text: isGenerating ? 'Generating...' : 'Generate with AI',
              isOutline: true,
              isLoading: isGenerating,
            ),
            if (referenceCaloriesBurned != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffFCE7F6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: _accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        text: '~$referenceCaloriesBurned kcal burned in $referenceDurationMinutes min (avg. adult, ${_avgWeightLabel}kg) - actual burn is computed per-patient at logging time',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: const Color(0xff6C737F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            CustomText(text: 'Difficulty', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xff1F2A37)),
            const SizedBox(height: 8),
            _chipRow(exerciseDifficultyLevels, selectedDifficulty, (v) => setState(() => selectedDifficulty = v)),
            const SizedBox(height: 16),
            CustomField(
              controller: metController,
              lable: 'MET value',
              hintText: 'e.g. 3.5 for brisk walking, 9.8 for running',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: secondsPerRepController,
              lable: 'Avg. seconds per rep (optional)',
              hintText: 'e.g. 3 for push-ups, 2 for jumping jacks - time to complete one rep',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: descriptionController,
              lable: 'Description',
              hintText: 'Brief description of the exercise and what it targets',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: instructionsController,
              lable: 'Instructions (comma-separated steps)',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: equipmentController,
              lable: 'Equipment (comma-separated)',
              hintText: 'e.g. Dumbbells, Mat',
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: muscleGroupsController,
              lable: 'Target muscle groups (comma-separated)',
              hintText: 'e.g. Legs, Core',
            ),
            const SizedBox(height: 16),
            CustomField(
              controller: videoUrlController,
              lable: 'Video URL (optional)',
              hintText: 'Paste a demo/tutorial link (e.g. YouTube)',
            ),
            const SizedBox(height: 32),
            CustomButton(
              onTap: _save,
              text: 'Save Exercise',
              isOutline: false,
              isLoading: isSaving,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static const _avgWeightLabel = 70;
}
