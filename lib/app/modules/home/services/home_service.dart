import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class HomeService {
  final ApiService service = ApiService();

  final String getAllPatientRequest = '/diet-plan-requests';

  Future<dynamic> getAllRequestedPatients() async {
    try {
      final response = await service.request(
        endPoint: getAllPatientRequest,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await service.request(
        endPoint: '/dashboard-stats',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
    return null;
  }

  Future<bool> acknowledgeNeedAttention(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/need-attention/$patientId/acknowledge',
        method: 'POST',
        headers: {'Authorization': "Bearer $token"},
      );
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('Acknowledge error: $e');
    }
    return false;
  }

  Future<dynamic> getPatientProfile(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/profile',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }
}
