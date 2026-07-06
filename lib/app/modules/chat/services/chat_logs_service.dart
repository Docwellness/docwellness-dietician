import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Service for Chat and Activity Logs APIs
class ChatLogsService {
  final ApiService service = ApiService();

  // ==================== CHAT APIs ====================

  /// Get all patient conversations
  Future<dynamic> getAllConversations() async {
    try {
      final response = await service.request(
        endPoint: '/chat/conversations',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getAllConversations error: $e');
    }
    return null;
  }

  /// Get messages for a specific conversation
  Future<dynamic> getConversationMessages(String conversationId) async {
    try {
      final response = await service.request(
        endPoint: '/chat/conversations/$conversationId/messages',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getConversationMessages error: $e');
    }
    return null;
  }

  /// Send a text message
  Future<dynamic> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    String? replyTo,
  }) async {
    try {
      final data = {
        "conversationId": conversationId,
        "receiverId": receiverId,
        "message": message,
      };

      if (replyTo != null && replyTo.isNotEmpty) {
        data["replyTo"] = replyTo;
      }

      final response = await service.request(
        endPoint: '/chat/message',
        method: 'POST',
        data: data,
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('sendMessage error: $e');
    }
    return null;
  }

  /// Send image message with optional text and reply
  Future<dynamic> sendImageMessage({
    required String receiverId,
    File? imageFile,
    String? message,
    String? replyTo,
  }) async {
    try {
      final formData = FormData();

      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
      }

      if (message != null && message.trim().isNotEmpty) {
        formData.fields.add(MapEntry('message', message.trim()));
      }

      if (replyTo != null && replyTo.isNotEmpty) {
        formData.fields.add(MapEntry('replyTo', replyTo));
      }

      final response = await service.request(
        endPoint: '/chat/message/$receiverId',
        method: 'POST',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }

      return response?.data;
    } catch (e) {
      debugPrint('sendImageMessage error: $e');
      return null;
    }
  }

  /// Mark messages as read
  Future<dynamic> markAsRead(String conversationId) async {
    try {
      final response = await service.request(
        endPoint: '/chat/conversations/$conversationId/read',
        method: 'POST',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
    return null;
  }

  // ==================== MEAL LOGS APIs ====================

  /// Get patient meal logs for a specific date
  Future<dynamic> getPatientMealLogs({
    required String patientId,
    String? date, // Format: YYYY-MM-DD
  }) async {
    try {
      String endpoint = '/patients/$patientId/meal-logs';
      if (date != null) {
        endpoint += '?date=$date';
      }

      final response = await service.request(
        endPoint: endpoint,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientMealLogs error: $e');
    }
    return null;
  }

  /// Get all meal logs for a patient (history)
  Future<dynamic> getPatientMealHistory({
    required String patientId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/meal-logs/history?page=$page&limit=$limit',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientMealHistory error: $e');
    }
    return null;
  }

  /// Get custom meals created by patient
  Future<dynamic> getPatientCustomMeals(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/custom-meals',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientCustomMeals error: $e');
    }
    return null;
  }

  /// Approve or reject a meal log
  Future<dynamic> updateMealLogStatus({
    required String patientId,
    required String mealLogId,
    required String status, // 'approved' or 'rejected'
    String? feedback,
  }) async {
    try {
      final data = {
        "status": status,
        if (feedback != null) "feedback": feedback,
      };

      final response = await service.request(
        endPoint: '/patients/$patientId/meal-logs/$mealLogId/status',
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
      debugPrint('updateMealLogStatus error: $e');
    }
    return null;
  }

  // ==================== ACTIVITY LOGS APIs ====================

  /// Get combined activity logs (chat + meals + other activities)
  Future<dynamic> getPatientActivityLogs({
    required String patientId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      String endpoint = '/patients/$patientId/activity-logs?page=$page&limit=$limit';

      if (startDate != null) {
        endpoint += '&startDate=$startDate';
      }
      if (endDate != null) {
        endpoint += '&endDate=$endDate';
      }

      final response = await service.request(
        endPoint: endpoint,
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getPatientActivityLogs error: $e');
    }
    return null;
  }

  /// Get today's activity summary
  Future<dynamic> getTodayActivitySummary(String patientId) async {
    try {
      final response = await service.request(
        endPoint: '/patients/$patientId/activity-logs/today-summary',
        method: 'GET',
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getTodayActivitySummary error: $e');
    }
    return null;
  }

  /// Add a note to patient's activity log
  Future<dynamic> addNoteToPatient({
    required String patientId,
    required String note,
    String? category,
  }) async {
    try {
      final data = {
        "note": note,
        if (category != null) "category": category,
      };

      final response = await service.request(
        endPoint: '/patients/$patientId/activity-logs/note',
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
      debugPrint('addNoteToPatient error: $e');
    }
    return null;
  }
}
