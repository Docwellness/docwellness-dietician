import 'dart:io';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class ChatService {
  final ApiService service = ApiService();

  final String getAllPatientsChatPath = '/chat/conversations';

  Future<dynamic> getAllPatientsChat() async {
    try {
      final response = await service.request(
        endPoint: getAllPatientsChatPath,
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

  Future<dynamic> getPatientChat(String id) async {
    debugPrint('-------------------$id');
    try {
      final response = await service.request(
        endPoint: '/chat/conversations/$id/messages',
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

  Future<dynamic> sendChat(Map<String, dynamic> data) async {
    debugPrint("---------1> $data");
    try {
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
      debugPrint('-----------------------> $e');
    }
    return null;
  }

  Future<dynamic> sendImageInChatOrReply({
    required String receiverId,
    File? imageFile,
    String? message,
    String? replyTo,
  }) async {
    try {
      final formData = FormData();

      //  Image
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

      //  Message
      if (message != null && message.trim().isNotEmpty) {
        formData.fields.add(MapEntry('message', message.trim()));
      }

      // ↩ Reply To
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
      debugPrint('❌ Send image error: $e');
      return null;
    }
  }

  Future<dynamic> readMessage(String id) async {
    try {
      final response = await service.request(
        endPoint: '/chat/conversations/$id/read',
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

  Future<String?> getOrCreateConversation(String participantId) async {
    try {
      final response = await service.request(
        endPoint: '/chat/conversations/get-or-create',
        method: 'POST',
        data: {'participantId': participantId},
        headers: {'Authorization': "Bearer $token"},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['id']?.toString();
      }
    } catch (e) {
      debugPrint('getOrCreateConversation error: $e');
    }
    return null;
  }
}
