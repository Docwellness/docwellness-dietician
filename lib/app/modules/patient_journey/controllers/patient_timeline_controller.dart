import 'package:docwellnesdoc/app/models/timeline_dto.dart';
import 'package:docwellnesdoc/app/modules/patient_journey/services/patient_timeline_service.dart';
import 'package:docwellnesdoc/app/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/timeline_models.dart';

enum PatientTimelineUiState { initial, loading, success, error }

/// One instance per patient card (see PatientJourneyCard's GetBuilder with
/// tag: userId) - not a shared/permanent singleton like the patient app's
/// TimelineController, since a dietician may view many different patients'
/// timelines in one session.
class PatientTimelineController extends GetxController {
  final PatientTimelineService service = PatientTimelineService();
  final String userId;
  final String patientName;

  PatientTimelineController({required this.userId, required this.patientName});

  final Rx<GoalDto?> goal = Rx<GoalDto?>(null);
  final Rx<TimelineStats?> stats = Rx<TimelineStats?>(null);
  final RxList<Milestone> milestones = <Milestone>[].obs;
  final Rx<PatientTimelineUiState> state = PatientTimelineUiState.initial.obs;

  @override
  void onInit() {
    super.onInit();
    load();

    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().onAdherenceChanged.listen((data) {
        if (data['patientId']?.toString() == userId) load(silent: true);
      });
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state.value = PatientTimelineUiState.loading;
    final dto = await service.getPatientTimeline(userId);
    if (dto == null || dto.goal == null) {
      if (!silent) state.value = PatientTimelineUiState.error;
      return;
    }
    goal.value = dto.goal;
    stats.value = dto.stats;
    milestones.assignAll(dto.milestones.map((e) => e.toDomain()));
    state.value = PatientTimelineUiState.success;
  }

  /// Same red/amber/green thresholds as PatientWidget._accentColor() (the
  /// patients-list tab's existing per-patient adherence styling) - reused
  /// here rather than inventing a separate palette for the same signal.
  Color adherenceColor(Milestone m) {
    if (m.status == MilestoneStatus.active) return const Color(0xff851653);
    if (m.date.isAfter(DateTime.now())) return const Color(0xffB98AA6);
    final adherencePercent = m.adherence * 100;
    if (adherencePercent < 40) return const Color(0xffDC2626);
    if (adherencePercent < 70) return const Color(0xffF59E0B);
    return const Color(0xff10B981);
  }

  String get riskLevel {
    final adherencePercent = (stats.value?.adherence30d ?? 0) * 100;
    if (adherencePercent < 40) return 'At risk';
    if (adherencePercent < 70) return 'Slipping';
    return 'On track';
  }

  Future<void> nudge({String? milestoneId, required String message}) async {
    await service.sendNudge(patientId: userId, milestoneId: milestoneId, message: message);
  }
}
