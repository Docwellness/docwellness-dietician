import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/foundation.dart';

/// Wraps the Phase 3 "Clever UX" endpoints (Week Tweak, Swap vs Scale,
/// Exception Review, Supplement Injection) added to
/// routes/dietician.js/dietPlanController.js alongside the deterministic
/// diet-plan engine. Kept separate from PatientService (which already has
/// 700+ lines) rather than growing that file further - the wizard's own
/// service, same request/response convention (ApiService.request, check
/// statusCode==200 && data['success']==true, return response.data or null).
class DietPlanWizardService {
  final ApiService service = ApiService();

  String _base(String patientId, String dietPlanId) =>
      '/patients/$patientId/diet-plans/$dietPlanId';

  Future<dynamic> applyWeekTweak({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String servingTime,
    required double multiplier,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/week-tweak',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'week': week, 'servingTime': servingTime, 'multiplier': multiplier},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('applyWeekTweak error: $e');
    }
    return null;
  }

  Future<dynamic> scaleItem({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String itemId,
    required double newMultiplier,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/swap',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          'week': week,
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'itemId': itemId,
          'action': 'scale',
          'newMultiplier': newMultiplier,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('scaleItem error: $e');
    }
    return null;
  }

  Future<dynamic> swapRecipe({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String itemId,
    required String newRecipeId,
    String? reason,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/swap',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          'week': week,
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'itemId': itemId,
          'action': 'swap',
          'newRecipeId': newRecipeId,
          if (reason != null) 'reason': reason,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('swapRecipe error: $e');
    }
    return null;
  }

  Future<dynamic> getSwapAlternatives({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String itemId,
    String? direction,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/swap-alternatives',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        queryParameters: {
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'itemId': itemId,
          if (direction != null) 'direction': direction,
        },
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getSwapAlternatives error: $e');
    }
    return null;
  }

  Future<dynamic> getWeekDays({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/days',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getWeekDays error: $e');
    }
    return null;
  }

  Future<dynamic> getExceptions({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/exceptions',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getExceptions error: $e');
    }
    return null;
  }

  Future<dynamic> upsertSupplement({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String supplementId,
    String? dosage,
    String? instructions,
    required String timingAnchor,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/supplements',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          'week': week,
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'supplementId': supplementId,
          if (dosage != null) 'dosage': dosage,
          if (instructions != null) 'instructions': instructions,
          'timingAnchor': timingAnchor,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('upsertSupplement error: $e');
    }
    return null;
  }
}
