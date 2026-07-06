import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class QuoteService {
  final ApiService _api = ApiService();

  /// Fetch all quotes for the dietician
  Future<List<Map<String, dynamic>>> getQuotes() async {
    try {
      final res = await _api.request(
        endPoint: '/quotes',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      log('QuoteService.getQuotes error: $e');
      return [];
    }
  }

  /// Add a new quote with image uploaded to Cloudinary
  Future<Map<String, dynamic>?> addQuote({
    required String imagePath,
    required bool isActive,
    String text = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'isActive': isActive.toString(),
        'text': text,
      });

      final res = await _api.request(
        endPoint: '/quotes',
        method: 'POST',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res != null &&
          (res.statusCode == 200 || res.statusCode == 201) &&
          res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('QuoteService.addQuote error: $e');
      return null;
    }
  }

  /// Update an existing quote
  Future<Map<String, dynamic>?> updateQuote({
    required String quoteId,
    String? imagePath,
    bool? isActive,
    String? text,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (isActive != null) map['isActive'] = isActive.toString();
      if (text != null) map['text'] = text;
      if (imagePath != null) {
        map['image'] = await MultipartFile.fromFile(imagePath);
      }

      final formData = FormData.fromMap(map);

      final res = await _api.request(
        endPoint: '/quotes/$quoteId',
        method: 'PUT',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('QuoteService.updateQuote error: $e');
      return null;
    }
  }

  /// Toggle active status of a quote
  Future<Map<String, dynamic>?> toggleActive(
    String quoteId,
    bool isActive,
  ) async {
    return updateQuote(quoteId: quoteId, isActive: isActive);
  }

  /// Delete a specific quote by ID
  Future<bool> deleteQuote(String quoteId) async {
    try {
      final res = await _api.request(
        endPoint: '/quotes/$quoteId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      return res != null &&
          res.statusCode == 200 &&
          res.data['success'] == true;
    } catch (e) {
      log('QuoteService.deleteQuote error: $e');
      return false;
    }
  }
}
