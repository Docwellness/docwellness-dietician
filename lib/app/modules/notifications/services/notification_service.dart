import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class NotificationService {
  final ApiService _api = ApiService();
  final Map<String, String> _authHeader = {'Authorization': 'Bearer $token'};

  /// Fetch paginated notifications
  Future<Map<String, dynamic>?> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.request(
        endPoint: '/notifications',
        method: 'GET',
        queryParameters: {'page': page, 'limit': limit},
        headers: _authHeader,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint('getNotifications error: $e');
    }
    return null;
  }

  /// Get unread count for badge
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/unread-count',
        method: 'GET',
        headers: _authHeader,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint('getUnreadCount error: $e');
    }
    return 0;
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String id) async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/$id/read',
        method: 'PUT',
        headers: _authHeader,
      );
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
    return false;
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.request(
        endPoint: '/notifications/read-all',
        method: 'PUT',
        headers: _authHeader,
      );
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
    return false;
  }
}
