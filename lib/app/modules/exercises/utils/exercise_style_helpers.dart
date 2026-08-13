import 'package:flutter/material.dart';

/// Shared category icon/color + difficulty color mapping - used by both
/// exercises_view.dart's catalog tiles and exercise_details_sheet.dart so
/// an exercise reads as the same visual "type" wherever it's shown, rather
/// than one flat pink block regardless of Cardio/Strength/Flexibility/Sports.
class ExerciseCategoryStyle {
  final IconData icon;
  final Color color;
  const ExerciseCategoryStyle(this.icon, this.color);
}

const Map<String, ExerciseCategoryStyle> exerciseCategoryStyles = {
  'Cardio': ExerciseCategoryStyle(Icons.directions_run_rounded, Color(0xffE5484D)),
  'Strength': ExerciseCategoryStyle(Icons.fitness_center_rounded, Color(0xff851653)),
  'Flexibility': ExerciseCategoryStyle(Icons.self_improvement_rounded, Color(0xff7C5CFC)),
  'Sports': ExerciseCategoryStyle(Icons.sports_tennis_rounded, Color(0xff0EA5E9)),
  'Other': ExerciseCategoryStyle(Icons.sports_gymnastics_rounded, Color(0xff6C737F)),
};

ExerciseCategoryStyle categoryStyleFor(String category) =>
    exerciseCategoryStyles[category] ?? exerciseCategoryStyles['Other']!;

const Map<String, Color> exerciseDifficultyColors = {
  'Beginner': Color(0xff1F8A5B),
  'Intermediate': Color(0xffD97706),
  'Advanced': Color(0xffDC2626),
};

Color difficultyColorFor(String difficulty) =>
    exerciseDifficultyColors[difficulty] ?? const Color(0xff851653);
