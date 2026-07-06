import 'dart:developer';

import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class PerformanceStatsService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getDietPlanRequests() async {
    try {
      final response = await _api.request(
        endPoint: '/diet-plan-requests',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      log('PerformanceStatsService.getDietPlanRequests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final response = await _api.request(
        endPoint: '/dashboard-stats',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
    } catch (e) {
      log('PerformanceStatsService.getDashboardStats error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPerformanceTrends() async {
    try {
      final response = await _api.request(
        endPoint: '/performance-trends',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
    } catch (e) {
      log('PerformanceStatsService.getPerformanceTrends error: $e');
    }
    return null;
  }
}
