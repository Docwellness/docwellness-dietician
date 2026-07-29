import 'package:flutter/material.dart';

import 'timeline_models.dart';

/// Raw JSON-shaped DTOs mirroring docwellness-backend's
/// utils/timelinePayload.js response contract - same shape as
/// docwellness-user's lib/app/models/timeline_dto.dart.
class TimelineDto {
  final GoalDto? goal;
  final TimelineStats? stats;
  final List<MilestoneDto> milestones;

  TimelineDto({required this.goal, required this.stats, required this.milestones});

  factory TimelineDto.fromJson(Map<String, dynamic> j) => TimelineDto(
        goal: j['goal'] != null ? GoalDto.fromJson(j['goal']) : null,
        stats: j['stats'] != null ? TimelineStats.fromJson(j['stats']) : null,
        milestones: (j['milestones'] as List? ?? [])
            .map((e) => MilestoneDto.fromJson(e))
            .toList(),
      );
}

class GoalDto {
  final String id, title, unit;
  final double startValue, currentValue, targetValue;
  final DateTime startDate, endDate;

  GoalDto({
    required this.id,
    required this.title,
    required this.unit,
    required this.startValue,
    required this.currentValue,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
  });

  factory GoalDto.fromJson(Map<String, dynamic> j) => GoalDto(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        unit: j['unit']?.toString() ?? 'kg',
        startValue: (j['startValue'] as num?)?.toDouble() ?? 0,
        currentValue: (j['currentValue'] as num?)?.toDouble() ?? 0,
        targetValue: (j['targetValue'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.tryParse(j['startDate']?.toString() ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(j['endDate']?.toString() ?? '') ?? DateTime.now(),
      );
}

class TimelineStats {
  final int streak, weekDone, weekTotal, daysToGo, daysElapsed;
  final double adherence30d;
  final bool? onPace;
  final DateTime? predictedEndDate;

  TimelineStats({
    required this.streak,
    required this.weekDone,
    required this.weekTotal,
    required this.daysToGo,
    required this.daysElapsed,
    required this.adherence30d,
    required this.onPace,
    this.predictedEndDate,
  });

  factory TimelineStats.fromJson(Map<String, dynamic> j) => TimelineStats(
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        weekDone: (j['weekDone'] as num?)?.toInt() ?? 0,
        weekTotal: (j['weekTotal'] as num?)?.toInt() ?? 7,
        daysToGo: (j['daysToGo'] as num?)?.toInt() ?? 0,
        daysElapsed: (j['daysElapsed'] as num?)?.toInt() ?? 0,
        adherence30d: (j['adherence30d'] as num?)?.toDouble() ?? 0,
        onPace: j['onPace'] as bool?,
        predictedEndDate: j['predictedEndDate'] != null
            ? DateTime.tryParse(j['predictedEndDate'].toString())
            : null,
      );
}

class MilestoneDto {
  final String id, type, title, subtitle, status;
  final DateTime date;
  final double adherence;
  final List<TaskDto> tasks;

  MilestoneDto({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.adherence,
    required this.tasks,
  });

  factory MilestoneDto.fromJson(Map<String, dynamic> j) => MilestoneDto(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? 'daily',
        title: j['title']?.toString() ?? '',
        subtitle: j['subtitle']?.toString() ?? '',
        status: j['status']?.toString() ?? 'upcoming',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        adherence: (j['adherence'] as num?)?.toDouble() ?? 0,
        tasks: (j['tasks'] as List? ?? []).map((e) => TaskDto.fromJson(e)).toList(),
      );

  Milestone toDomain() => Milestone(
        id: id,
        title: title,
        subtitle: subtitle,
        date: date,
        type: _typeFromString(type),
        status: MilestoneStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => MilestoneStatus.upcoming,
        ),
        adherence: adherence,
        tasks: tasks.map((t) => t.toDomain()).toList(),
      );

  static MilestoneType _typeFromString(String value) {
    if (value == 'end_goal') return MilestoneType.endGoal;
    return MilestoneType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MilestoneType.daily,
    );
  }
}

class TaskDto {
  final String id, title, metric, icon;
  final bool done, linked;
  final String? loggedNote;
  final double? progress;

  TaskDto({
    required this.id,
    required this.title,
    required this.metric,
    required this.icon,
    required this.done,
    this.linked = false,
    this.loggedNote,
    this.progress,
  });

  factory TaskDto.fromJson(Map<String, dynamic> j) => TaskDto(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        metric: j['metric']?.toString() ?? '',
        icon: j['icon']?.toString() ?? '',
        done: j['done'] == true,
        linked: j['linked'] == true,
        loggedNote: j['loggedNote']?.toString(),
        progress: (j['progress'] as num?)?.toDouble(),
      );

  GoalTask toDomain() => GoalTask(
        id: id,
        title: title,
        metric: metric,
        icon: goalTaskIconMap[icon] ?? Icons.circle_outlined,
        done: done,
        linked: linked,
        loggedNote: loggedNote,
        progress: progress,
      );
}
