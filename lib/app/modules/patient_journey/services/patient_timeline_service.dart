import 'package:docwellnesdoc/app/models/timeline_dto.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

/// Backend calls for the dietician-side Goal Journey Timeline - built on
/// the shared ApiService wrapper, same pattern as PatientService.
class PatientTimelineService {
  final ApiService service = ApiService();

  Future<TimelineDto?> getPatientTimeline(String patientId, {int from = -30, int to = 30}) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/timeline?from=$from&to=$to',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        return TimelineDto.fromJson(Map<String, dynamic>.from(response.data['data']));
      }
    } catch (e) {
      debugPrint('getPatientTimeline error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDayLogs(String patientId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      final response = await service.request(
        endPoint: '/patients/$patientId/days/$dateStr/logs',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('getDayLogs error: $e');
    }
    return null;
  }

  Future<bool> sendNudge({required String patientId, String? milestoneId, required String message}) async {
    try {
      final response = await service.request(
        endPoint: '/nudges',
        method: 'POST',
        data: {
          'userId': patientId,
          if (milestoneId != null) 'milestoneId': milestoneId,
          'message': message,
        },
        headers: {'Authorization': 'Bearer $token'},
      );
      return response != null && response.statusCode == 201 && response.data['success'] == true;
    } catch (e) {
      debugPrint('sendNudge error: $e');
      return false;
    }
  }
}
