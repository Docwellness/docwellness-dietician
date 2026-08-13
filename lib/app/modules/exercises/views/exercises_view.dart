import 'package:docwellnesdoc/app/modules/exercises/controllers/exercises_controller.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/modules/exercises/utils/exercise_style_helpers.dart';
import 'package:docwellnesdoc/app/modules/exercises/views/add_exercise_view.dart';
import 'package:docwellnesdoc/app/modules/exercises/widgets/exercise_details_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Standalone screen wrapper around ExercisesTabBody. The bottom-nav tab
/// itself now uses DietAndExerciseView (home/views/diet_and_exercise_view.dart),
/// which embeds ExercisesTabBody directly inside a swipeable Recipes/
/// Exercises PageView instead of this Scaffold.
class ExercisesView extends StatelessWidget {
  const ExercisesView({super.key});

  static const _headerColor = Color(0xffFDF2FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        title: CustomText(
          text: 'Exercises',
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
      ),
      body: const ExercisesTabBody(),
    );
  }
}

/// Exercise catalog browse content: mirrors RecipesTabBody's landing pattern
/// (top category chip strip + list), simplified to a flat list since
/// exercises don't need Recipe's serving-time/cuisine grid. The "add" action
/// is an inline pinned bottom button (like RecipesTabBody's "Add New
/// Recipe") rather than a Scaffold-level FloatingActionButton, so both tabs
/// read consistently when swiped between inside DietAndExerciseView.
class ExercisesTabBody extends StatefulWidget {
  const ExercisesTabBody({super.key});

  @override
  State<ExercisesTabBody> createState() => _ExercisesTabBodyState();
}

class _ExercisesTabBodyState extends State<ExercisesTabBody> {
  late final ExercisesController controller;

  static const _headerColor = Color(0xffFDF2FA);
  static const _accent = Color(0xff851653);

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ExercisesController>()) {
      Get.put(ExercisesController());
    }
    controller = Get.find<ExercisesController>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _headerColor,
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', ...exerciseCategories].map((cat) {
                  final isSelected = controller.selectedCategory.value == cat;
                  final style = cat == 'All' ? null : categoryStyleFor(cat);
                  final chipColor = isSelected ? (style?.color ?? _accent) : Colors.white;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.setCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? chipColor : const Color(0xffE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (style != null) ...[
                              Icon(style.icon, size: 14, color: isSelected ? Colors.white : style.color),
                              const SizedBox(width: 6),
                            ],
                            CustomText(
                              text: cat,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: isSelected ? Colors.white : const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: _accent));
            }
            if (controller.exercises.isEmpty) {
              return Center(
                child: CustomText(
                  text: 'No exercises yet - tap "Add Exercise" below',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: const Color(0xff6C737F),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _ExerciseTile(exercise: controller.exercises[index]),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            onTap: () async {
              await Get.to(() => const AddExerciseView());
            },
            text: 'Add Exercise',
            isOutline: false,
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyleFor(exercise.category);
    final difficultyColor = difficultyColorFor(exercise.difficultyLevel);
    final referenceCalories = (exercise.met * 70 * 0.5).round();

    return GestureDetector(
      onTap: () => showExerciseDetailsSheet(context, exercise),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.color.withValues(alpha: 0.85), style.color],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: exercise.name, fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xff1F2A37)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: difficultyColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      CustomText(
                        text: '${exercise.difficultyLevel} • MET ${exercise.met} • ~$referenceCalories kcal/30min',
                        fontWeight: FontWeight.w400,
                        fontSize: 11.5,
                        color: const Color(0xff6C737F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (exercise.videoUrl.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.play_circle_fill_rounded, color: Color(0xff851653), size: 18),
              ),
            const Icon(Icons.chevron_right, color: Color(0xff9DA4AE)),
          ],
        ),
      ),
    );
  }
}
