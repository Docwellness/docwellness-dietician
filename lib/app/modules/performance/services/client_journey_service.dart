import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

/// API access for the dietician's Client Journeys (before/after + review
/// stories shown on their patients' Home screens).
class ClientJourneyService {
  final ApiService _api = ApiService();

  Map<String, String> get _auth => {'Authorization': 'Bearer $token'};

  Future<List<Map<String, dynamic>>> getJourneys() async {
    try {
      final res = await _api.request(
        endPoint: '/client-journeys',
        method: 'GET',
        headers: _auth,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
    } catch (e) {
      log('ClientJourneyService.getJourneys error: $e');
    }
    return [];
  }

  /// [reviewImagePath] and [reviewText] are mutually exclusive - the server
  /// rejects both together.
  Future<Map<String, dynamic>?> addJourney({
    required String beforePath,
    required String afterPath,
    String title = '',
    String? reviewImagePath,
    String reviewText = '',
    bool isActive = true,
  }) async {
    try {
      final form = FormData.fromMap({
        'title': title,
        'isActive': isActive.toString(),
        if (reviewText.isNotEmpty) 'reviewText': reviewText,
        'beforeImage': await MultipartFile.fromFile(beforePath),
        'afterImage': await MultipartFile.fromFile(afterPath),
        if (reviewImagePath != null)
          'reviewImage': await MultipartFile.fromFile(reviewImagePath),
      });
      final res = await _api.request(
        endPoint: '/client-journeys',
        method: 'POST',
        data: form,
        headers: _auth,
      );
      if (res != null &&
          (res.statusCode == 200 || res.statusCode == 201) &&
          res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (e) {
      log('ClientJourneyService.addJourney error: $e');
    }
    return null;
  }

  /// Only the fields that are passed change. Review semantics (server side):
  /// a [reviewImagePath] makes the review an image, a non-empty [reviewText]
  /// makes it text, [removeReview] clears it.
  Future<Map<String, dynamic>?> updateJourney({
    required String journeyId,
    String? title,
    bool? isActive,
    String? beforePath,
    String? afterPath,
    String? reviewImagePath,
    String? reviewText,
    bool removeReview = false,
  }) async {
    try {
      final form = FormData.fromMap({
        if (title != null) 'title': title,
        if (isActive != null) 'isActive': isActive.toString(),
        if (reviewText != null) 'reviewText': reviewText,
        if (removeReview) 'removeReview': 'true',
        if (beforePath != null)
          'beforeImage': await MultipartFile.fromFile(beforePath),
        if (afterPath != null)
          'afterImage': await MultipartFile.fromFile(afterPath),
        if (reviewImagePath != null)
          'reviewImage': await MultipartFile.fromFile(reviewImagePath),
      });
      final res = await _api.request(
        endPoint: '/client-journeys/$journeyId',
        method: 'PUT',
        data: form,
        headers: _auth,
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data']);
      }
    } catch (e) {
      log('ClientJourneyService.updateJourney error: $e');
    }
    return null;
  }

  Future<bool> deleteJourney(String journeyId) async {
    try {
      final res = await _api.request(
        endPoint: '/client-journeys/$journeyId',
        method: 'DELETE',
        headers: _auth,
      );
      return res != null &&
          res.statusCode == 200 &&
          res.data['success'] == true;
    } catch (e) {
      log('ClientJourneyService.deleteJourney error: $e');
      return false;
    }
  }
}
