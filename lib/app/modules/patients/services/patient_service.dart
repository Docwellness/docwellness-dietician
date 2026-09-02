import 'package:dio/dio.dart' as dio;
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class PatientService {
  final ApiService service = ApiService();

  /// Fetch patients by tab (ongoing, new, past) with pagination and an
  /// optional server-side name [search].
  Future<dynamic> getPatientsByTab({
    required String tab,
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final q = search.trim().isEmpty
          ? ''
          : '&search=${Uri.encodeQueryComponent(search.trim())}';
      final response = await service.request(
        endPoint: '/patients?tab=$tab&page=$page&limit=$limit$q',
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

  /// Permanently deletes a patient and all their data. `confirmEmail`
  /// must exactly match the patient's email - the backend
  /// (patientController.js's deletePatient) re-verifies this and rejects
  /// the request otherwise. Returns the raw response body (even on
  /// failure) so the caller can surface the backend's specific error
  /// message (e.g. an email mismatch) instead of a generic failure toast.
  Future<dynamic> deletePatient(String patientId, String confirmEmail) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId',
        method: 'DELETE',
        headers: {'Authorization': "Bearer $token"},
        data: {'confirmEmail': confirmEmail},
      );
      return response?.data;
    } catch (e) {
      debugPrint('deletePatient error: $e');
      return null;
    }
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

      // Surface the failure payload too (e.g. the backend's 502 "AI
      // diet-plan generation produced severe, unresolvable issues..."
      // message), not just the success payload - same fix as generateWeek
      // below. Without this the caller only ever sees null on failure and
      // has no way to tell the dietician *why* generation failed.
      if (response != null && response.data is Map) {
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

  /// Lightweight alternative to generateWeek - moves just this week's date
  /// (cascading every later week to follow it, see the backend's
  /// cascadeWeekScheduleFrom) without touching content/strategy.
  Future<dynamic> updateWeekScheduleDate(
    String patientId,
    String dietPlanId,
    int week,
    DateTime startDate,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/weeks/$week/schedule',
        method: 'PATCH',
        headers: {'Authorization': "Bearer $token"},
        data: {'startDate': startDate.toIso8601String()},
      );

      if (response != null && response.data is Map) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  /// Moves the whole diet's start date (the one editable field in Basic
  /// Information) - updates the request and cascades the active diet plan's
  /// week schedule and the exercise plan's start date, all server-side.
  Future<dynamic> updateDietStartDate(String patientId, DateTime startDate) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-start-date',
        method: 'PATCH',
        headers: {'Authorization': "Bearer $token"},
        data: {'startDate': startDate.toIso8601String()},
      );
      if (response != null && response.data is Map) {
        return response.data;
      }
    } catch (e) {
      debugPrint('updateDietStartDate error: $e');
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
      // A data-level rejection (e.g. 422 - days outside the calorie
      // tolerance) still carries an explanatory `message` the Finalize step
      // shows verbatim. Only a genuine no-response failure returns null.
      if (response != null && response.data is Map) {
        return response.data;
      }
    } catch (e) {
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  /// AI_EXECUTION_PLAN.md Phase 7, P7-05: save-draft - persists the
  /// dietician's in-progress selections without finalizing (no publish,
  /// no validation gate), so closing this screen mid-edit doesn't silently
  /// discard them back to the AI's raw draft on re-open. Same request
  /// shape as finalizeWeek (buildFinalizeWeekPayload is reused for both).
  Future<dynamic> saveDraftWeek(
    Map<String, dynamic> data,
    String patientId,
    String dietPlanId,
  ) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/diet-plans/$dietPlanId/save-draft',
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
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final params = <String>[
        if (startDate != null) 'startDate=${fmt(startDate)}',
        if (endDate != null) 'endDate=${fmt(endDate)}',
      ];
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await service.request(
        endPoint: '/patients/$patientId/tracking-data$query',
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

  /// Fetch patient exercise stats (calories burned, completion) for a
  /// specific date - mirrors fetchPatientMealLogStats/
  /// fetchPatientWaterIntake exactly.
  Future<dynamic> fetchPatientExerciseStats(
    String patientId, {
    String? date,
  }) async {
    try {
      final dateQuery = date != null ? '?date=$date' : '';
      final response = await service.request(
        endPoint: '/patients/$patientId/exercise-log/today-stats$dateQuery',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('fetchPatientExerciseStats error: $e');
    }
    return null;
  }
}
