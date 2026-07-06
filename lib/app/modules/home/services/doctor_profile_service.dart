import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/models/doctor_profile_model.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class DoctorProfileService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> get _headers => {'Authorization': 'Bearer $token'};

  Future<DoctorProfileModel?> getProfile() async {
    try {
      final response = await _apiService.request(
        endPoint: '/profile',
        method: 'GET',
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return DoctorProfileModel.fromJson(response.data['data']);
      }
    } catch (e) {
      log('❌ Error fetching doctor profile: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getPosts() async {
    try {
      final response = await _apiService.request(
        endPoint: '/quotes',
        method: 'GET',
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      log('❌ Error fetching doctor posts: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> addPost({
    required String imagePath,
    String? text,
    bool isActive = true,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'text': text ?? '',
        'isActive': isActive,
      });

      final response = await _apiService.request(
        endPoint: '/quotes',
        method: 'POST',
        data: formData,
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
    } catch (e) {
      log('❌ Error adding doctor post: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updatePost({
    required String postId,
    String? imagePath,
    String? text,
    bool? isActive,
  }) async {
    try {
      Object data = {
        if (text != null) 'text': text,
        if (isActive != null) 'isActive': isActive,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        data = FormData.fromMap({
          if (text != null) 'text': text,
          if (isActive != null) 'isActive': isActive,
          'image': await MultipartFile.fromFile(imagePath),
        });
      }

      final response = await _apiService.request(
        endPoint: '/quotes/$postId',
        method: 'PUT',
        data: data,
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
    } catch (e) {
      log('❌ Error updating doctor post: $e');
    }
    return null;
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await _apiService.request(
        endPoint: '/quotes/$postId',
        method: 'DELETE',
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      log('❌ Error deleting doctor post: $e');
    }
    return false;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.request(
        endPoint: '/profile',
        method: 'PUT',
        data: data,
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return true;
      }
    } catch (e) {
      log('❌ Error updating doctor profile: $e');
    }
    return false;
  }

  Future<String?> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.request(
        endPoint: '/profile/image',
        method: 'POST',
        data: formData,
        headers: _headers,
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['imageUrl'];
      }
    } catch (e) {
      log('❌ Error uploading profile image: $e');
    }
    return null;
  }
}
