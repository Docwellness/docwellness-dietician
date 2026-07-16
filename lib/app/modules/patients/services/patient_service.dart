import 'package:dio/dio.dart' as dio;
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class PatientService {
  final ApiService service = ApiService();

  /// Fetch patients by tab (ongoing, new, past) with pagination
  Future<dynamic> getPatientsByTab({
    required String tab,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await service.request(
        endPoint: '/patients?tab=$tab&page=$page&limit=$limit',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientsByTab error: $e');
    }
    return null;
  }

  Future<dynamic> sendConsultation(dio.FormData data, String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/first-consultation',
        method: 'PUT',
        data: data,
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
       
  Future<dynamic> togglePatientActive(String patientId, bool isActive) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/deactivate',
        method: 'PUT',
        headers: {'Authorization': "Bearer $token"},
        data: {'isActive': isActive},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('togglePatientActive error: $e');
    }
    return null;
  }

  Future<dynamic> generateDietPlan(
    Map<String, dynamic> data,
    String patientId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/generate',
        method: 'POST',
        headers: {'Authorization': "Bearer $token"},
        data: data,
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  Future<dynamic> generateWeek(
    Map<String, dynamic> data,
    String patientId,
    String dietPlanId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/generate-week',
        method: 'POST',
        headers: {'Authorization': "Bearer $token"},
        data: data,
      );

      if (response != null) {
        // Surface the tier-gating 403/validation 400 message too, not just
        // the success payload - the caller distinguishes via 'success'.
        if (response.data is Map) {
          return response.data;
        }
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  Future<dynamic> getAiGeneratedDietPlan(
    String patientId,
    String dietPlanId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/details',
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

  Future<dynamic> getConsultation(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/first-consultation',
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

  Future<dynamic> getManualProofs(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/payments/manual-proofs',
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

  Future<dynamic> rejectPaymentProof(
    String patientId,
    String proofId,
    String reviewNote,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/payments/manual-proofs/$proofId/reject',
        method: 'PUT',
        headers: {'Authorization': "Bearer $token"},
        data: {'reviewNote': reviewNote},
      );

      if (response != null) {
        if (response.statusCode == 200 && response.data['success'] == true) {
          return response.data;
        } else {
          return response.data;
        }
      }
    } catch (e) {
      debugPrint('-----------------------> Reject payment error: $e');
    }
    return null;
  }

  Future<dynamic> confirmRenewalPayment(String patientId, String proofId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/payments/manual-proofs/$proofId/confirm',
        method: 'PUT',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> Confirm renewal payment error: $e');
    }
    return null;
  }

  Future<dynamic> finalizeWeek(
    Map<String, dynamic> data,
    String patientId,
    String dietPlanId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/finalize-week',
        method: 'PUT',
        headers: {'Authorization': "Bearer $token"},
        data: data,
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

  Future<dynamic> finalizeAll(
    Map<String, dynamic> data,
    String patientId,
    String dietPlanId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/finalize-all',
        method: 'PUT',
        headers: {'Authorization': "Bearer $token"},
        data: data,
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

  Future<dynamic> sendPaymentRequest(String patientId, String requestId) async {
    try {
      final response = await service.request(
        endPoint:
            '/patients/$patientId/diet-plan-requests/$requestId/payment-request',
        method: 'POST',
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

  Future<dynamic> activateDietPlan(
    String patientId,
    String dietPlanId, {
    String? proofId,
    double? amountReceived,
    double? amountPending,
  }) async {
    try {
      debugPrint(
        '📡 Calling activate API: /patients/$patientId/diet-plans/$dietPlanId/activate',
      );
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/activate',
        method: 'POST',
        headers: {'Authorization': "Bearer $token"},
        data: {
          if (proofId != null && proofId.isNotEmpty) 'proofId': proofId,
          if (amountReceived != null) 'amountReceived': amountReceived,
          if (amountPending != null) 'amountPending': amountPending,
        },
      );

      debugPrint(
        '📡 Activate response: ${response?.statusCode} - ${response?.data}',
      );

      if (response != null) {
        if (response.statusCode == 200 && response.data['success'] == true) {
          return response.data;
        } else {
          // Return error response to show message
          return response.data;
        }
      }
    } catch (e) {
      debugPrint('-----------------------> Activate error: $e');
    }
    return null;
  }

  Future<dynamic> getSelectedDiet(
    String patientId,
    String dietPlanId,
    int week,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/weeks/$week',
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

  /// Same shape as [getSelectedDiet] but for a not-yet-finalized (Draft)
  /// week - returns the full recipe options pool per servingTime (AI's
  /// pick(s) pre-flagged isSelected), not just the single recipe the AI
  /// assigned.
  Future<dynamic> getDraftWeekOptions(
    String patientId,
    String dietPlanId,
    int week,
  ) async {
    try {
      final response = await service.request(
        endPoint:
            '/patients/$patientId/diet-plans/$dietPlanId/weeks/$week/draft-options',
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

  /// Fetch patient tracking data (calorie intake, weight trend, BMI)
  /// [period] can be 'week', 'month', or 'year'
  Future<dynamic> getPatientTrackingData(
    String patientId,
    String period,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/tracking-data?period=$period',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientTrackingData error: $e');
    }
    return null;
  }

  // ===== Journey Image APIs =====

  /// Get auto-generated milestone journey for a patient (from body logs)
  Future<dynamic> getPatientJourneyMilestones(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/journey/milestones',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientJourneyMilestones error: $e');
    }
    return null;
  }

  Future<dynamic> getPatientJourneyImages(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/journey',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientJourneyImages error: $e');
    }
    return null;
  }

  Future<dynamic> uploadJourneyImage(
    String patientId,
    dio.FormData data,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/journey',
        method: 'POST',
        data: data,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('uploadJourneyImage error: $e');
    }
    return null;
  }

  Future<dynamic> updateJourneyImage(
    String patientId,
    String imageId,
    dio.FormData data,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/journey/$imageId',
        method: 'PUT',
        data: data,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('updateJourneyImage error: $e');
    }
    return null;
  }

  Future<dynamic> deleteJourneyImage(String patientId, String imageId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/journey/$imageId',
        method: 'DELETE',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('deleteJourneyImage error: $e');
    }
    return null;
  }

  /// Send a doctor note to a patient
  Future<dynamic> sendDoctorNote({
    required String patientId,
    required String noteContent,
    String? noteDate,
  }) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/notes',
        method: 'POST',
        data: {
          'noteContent': noteContent,
          if (noteDate != null) 'noteDate': noteDate,
        },
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('sendDoctorNote error: $e');
    }
    return null;
  }

  /// Fetch all doctor notes for a patient
  Future<dynamic> fetchDoctorNotes(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/notes',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('fetchDoctorNotes error: $e');
    }
    return null;
  }

  /// Fetch patient meal log stats for a specific date
  Future<dynamic> fetchPatientMealLogStats(
    String patientId, {
    String? date,
  }) async {
    try {
      final dateQuery = date != null ? '?date=$date' : '';
      final response = await service.request(
        endPoint: '/patients/$patientId/meal-log/today-stats$dateQuery',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('fetchPatientMealLogStats error: $e');
    }
    return null;
  }

  /// Fetch patient water intake for a specific date
  Future<dynamic> fetchPatientWaterIntake(
    String patientId, {
    String? date,
  }) async {
    try {
      final dateQuery = date != null ? '?date=$date' : '';
      final response = await service.request(
        endPoint: '/patients/$patientId/water/today$dateQuery',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('fetchPatientWaterIntake error: $e');
    }
    return null;
  }
}
