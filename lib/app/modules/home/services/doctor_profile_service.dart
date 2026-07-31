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

  // ---- Social Media (About Doctor page - YouTube/Instagram) ----

  Future<List<Map<String, dynamic>>> getSocialPosts() async {
    try {
      final response = await _apiService.request(
        endPoint: '/social-media',
        method: 'GET',
        headers: _headers,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      log('❌ Error fetching social posts: $e');
    }
    return [];
  }

  Future<bool> addSocialPost({
    required String platform,
    required String url,
    String? imagePath,
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'platform': platform,
        'url': url,
        'caption': caption ?? '',
        if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiService.request(
        endPoint: '/social-media',
        method: 'POST',
        data: formData,
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error adding social post: $e');
      return false;
    }
  }

  Future<bool> deleteSocialPost(String id) async {
    try {
      final response = await _apiService.request(
        endPoint: '/social-media/$id',
        method: 'DELETE',
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error deleting social post: $e');
      return false;
    }
  }

  Future<bool> reorderSocialPosts(String platform, List<String> orderedIds) async {
    try {
      final response = await _apiService.request(
        endPoint: '/social-media/reorder',
        method: 'PUT',
        data: {'platform': platform, 'orderedIds': orderedIds},
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error reordering social posts: $e');
      return false;
    }
  }

  // ---- Articles (About Doctor page) ----

  Future<List<Map<String, dynamic>>> getArticles() async {
    try {
      final response = await _apiService.request(
        endPoint: '/articles',
        method: 'GET',
        headers: _headers,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      log('❌ Error fetching articles: $e');
    }
    return [];
  }

  Future<bool> addArticle({
    required String title,
    required String imagePath,
    String? category,
    String? excerpt,
    String? content,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'category': category ?? '',
        'excerpt': excerpt ?? '',
        'content': content ?? '',
        'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiService.request(
        endPoint: '/articles',
        method: 'POST',
        data: formData,
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error adding article: $e');
      return false;
    }
  }

  Future<bool> deleteArticle(String id) async {
    try {
      final response = await _apiService.request(
        endPoint: '/articles/$id',
        method: 'DELETE',
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error deleting article: $e');
      return false;
    }
  }

  Future<bool> reorderArticles(List<String> orderedIds) async {
    try {
      final response = await _apiService.request(
        endPoint: '/articles/reorder',
        method: 'PUT',
        data: {'orderedIds': orderedIds},
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error reordering articles: $e');
      return false;
    }
  }

  // ---- Reviews (About Doctor page - patient-submitted, dietician-sorted) ----

  Future<List<Map<String, dynamic>>> getReviews() async {
    try {
      final response = await _apiService.request(
        endPoint: '/reviews',
        method: 'GET',
        headers: _headers,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      log('❌ Error fetching reviews: $e');
    }
    return [];
  }

  Future<bool> deleteReview(String id) async {
    try {
      final response = await _apiService.request(
        endPoint: '/reviews/$id',
        method: 'DELETE',
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error deleting review: $e');
      return false;
    }
  }

  Future<bool> reorderReviews(List<String> orderedIds) async {
    try {
      final response = await _apiService.request(
        endPoint: '/reviews/reorder',
        method: 'PUT',
        data: {'orderedIds': orderedIds},
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error reordering reviews: $e');
      return false;
    }
  }

  // ---- Photo Gallery (About Doctor page - auto-scrolling carousel) ----

  Future<List<Map<String, dynamic>>> getGalleryImages() async {
    try {
      final response = await _apiService.request(
        endPoint: '/profile',
        method: 'GET',
        headers: _headers,
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']?['galleryImages'] ?? []);
      }
    } catch (e) {
      log('❌ Error fetching gallery images: $e');
    }
    return [];
  }

  Future<bool> addGalleryImage(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });
      final response = await _apiService.request(
        endPoint: '/profile/gallery',
        method: 'POST',
        data: formData,
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error adding gallery image: $e');
      return false;
    }
  }

  Future<bool> deleteGalleryImage(String id) async {
    try {
      final response = await _apiService.request(
        endPoint: '/profile/gallery/$id',
        method: 'DELETE',
        headers: _headers,
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      log('❌ Error deleting gallery image: $e');
      return false;
    }
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
