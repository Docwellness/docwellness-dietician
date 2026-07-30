import 'package:flutter/material.dart';

/// Goal Journey Timeline domain classes - mirrors docwellness-user's
/// lib/app/models/timeline_models.dart (no shared package between the two
/// Flutter apps today, same as tracking_data_model.dart already existing
/// independently in both repos).

enum MilestoneType { daily, weekly, monthly, endGoal }

enum MilestoneStatus { completed, missed, active, upcoming }

const Map<String, IconData> goalTaskIconMap = {
  'morning_drink': Icons.local_cafe,
  'breakfast': Icons.free_breakfast,
  'brunch': Icons.brunch_dining,
  'lunch': Icons.rice_bowl,
  'evening_snack': Icons.eco,
  'dinner': Icons.dinner_dining,
  'night_drink': Icons.nightlight_round,
  'supplements': Icons.medication,
  'restaurant': Icons.restaurant_menu,
  'water_drop': Icons.water_drop,
  'walk': Icons.directions_walk,
  'sleep': Icons.bedtime,
  'weight': Icons.monitor_weight,
  'camera': Icons.camera_alt,
  'chat': Icons.chat_bubble,
};

class GoalTask {
  final String id;
  final String title;
  final String metric;
  final IconData icon;
  final bool done;
  // See docwellness-user's timeline_models.dart's GoalTask.linked doc
  // comment - true for a meal-linked task or Water Intake (done from the
  // patient's real MealLog/WaterLog, not manually checked).
  final bool linked;
  final String? loggedNote;
  // 0..1, only meaningful for the Water Intake task.
  final double? progress;

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
    this.linked = false,
    this.loggedNote,
    this.progress,
  });
}

/// See docwellness-user's timeline_models.dart's mealGroupTaskTitles/
/// waterTaskTitle/TaskGroups doc comments - same grouping, duplicated here
/// (no shared package between the two Flutter apps).
const Set<String> mealGroupTaskTitles = {
  'Morning Drink',
  'Breakfast',
  'Brunch',
  'Lunch',
  'Evening Snack',
  'Dinner',
  'Night Drink',
  'Supplements',
};

const String waterTaskTitle = 'Water Intake';

class TaskGroups {
  final List<GoalTask> mealTasks;
  final GoalTask? waterTask;
  final List<GoalTask> otherTasks;

  TaskGroups({required this.mealTasks, required this.waterTask, required this.otherTasks});

  int get mealDone => mealTasks.where((t) => t.done).length;
  int get mealTotal => mealTasks.length;
  bool get mealComplete => mealTotal > 0 && mealDone == mealTotal;

  factory TaskGroups.from(List<GoalTask> tasks) {
    final meal = tasks.where((t) => mealGroupTaskTitles.contains(t.title)).toList();
    GoalTask? water;
    final others = <GoalTask>[];
    for (final t in tasks) {
      if (mealGroupTaskTitles.contains(t.title)) continue;
      if (t.title == waterTaskTitle) {
        water = t;
      } else {
        others.add(t);
      }
    }
    return TaskGroups(mealTasks: meal, waterTask: water, otherTasks: others);
  }
}

class Milestone {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final MilestoneType type;
  final MilestoneStatus status;
  final double adherence;
  final List<GoalTask> tasks;

  Milestone({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.status,
    required this.adherence,
    required this.tasks,
  });
}
