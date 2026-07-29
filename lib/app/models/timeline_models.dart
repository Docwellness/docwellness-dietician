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
  'lunch': Icons.lunch_dining,
  'evening_snack': Icons.cookie,
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
  // comment - true for a meal-linked task (done from the patient's real
  // MealLog, not manually checked).
  final bool linked;
  final String? loggedNote;

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
    this.linked = false,
    this.loggedNote,
  });
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
