import 'package:flutter/material.dart';

/// Goal Journey Timeline domain classes - mirrors docwellness-user's
/// lib/app/models/timeline_models.dart (no shared package between the two
/// Flutter apps today, same as tracking_data_model.dart already existing
/// independently in both repos).

enum MilestoneType { daily, weekly, monthly, endGoal }

enum MilestoneStatus { completed, missed, active, upcoming }

const Map<String, IconData> goalTaskIconMap = {
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

  GoalTask({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
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
