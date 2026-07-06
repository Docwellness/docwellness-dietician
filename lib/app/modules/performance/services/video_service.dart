import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class VideoService {
  final ApiService _api = ApiService();

  /// Fetch all videos for the dietician
  Future<List<Map<String, dynamic>>> getVideos() async {
    try {
      final res = await _api.request(
        endPoint: '/videos',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      log('VideoService.getVideos error: $e');
      return [];
    }
  }

  /// Add a new video
  Future<Map<String, dynamic>?> addVideo({
    required String source,
    String? title,
    String? youtubeUrl,
    String? thumbnailUrl,
    required bool visibleToUser,
    String? bannerImagePath,
    String? videoFilePath,
    String text = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'source': source,
        'title': title ?? '',
        'youtubeUrl': youtubeUrl ?? '',
        'thumbnailUrl': thumbnailUrl ?? '',
        'visibleToUser': visibleToUser.toString(),
        'text': text,
        if (bannerImagePath != null)
          'bannerImage': await MultipartFile.fromFile(bannerImagePath),
        if (videoFilePath != null)
          'videoFile': await MultipartFile.fromFile(videoFilePath),
      });

      final res = await _api.request(
        endPoint: '/videos',
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
      log('VideoService.addVideo error: $e');
      return null;
    }
  }

  /// Update an existing video
  Future<Map<String, dynamic>?> updateVideo({
    required String videoId,
    String? source,
    String? title,
    String? youtubeUrl,
    String? thumbnailUrl,
    bool? visibleToUser,
    String? bannerImagePath,
    String? videoFilePath,
    String? text,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (source != null) map['source'] = source;
      if (title != null) map['title'] = title;
      if (youtubeUrl != null) map['youtubeUrl'] = youtubeUrl;
      if (thumbnailUrl != null) map['thumbnailUrl'] = thumbnailUrl;
      if (visibleToUser != null) {
        map['visibleToUser'] = visibleToUser.toString();
      }
      if (text != null) map['text'] = text;
      if (bannerImagePath != null) {
        map['bannerImage'] = await MultipartFile.fromFile(bannerImagePath);
      }
      if (videoFilePath != null) {
        map['videoFile'] = await MultipartFile.fromFile(videoFilePath);
      }

      final formData = FormData.fromMap(map);

      final res = await _api.request(
        endPoint: '/videos/$videoId',
        method: 'PUT',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('VideoService.updateVideo error: $e');
      return null;
    }
  }

  /// Toggle visibility of a video
  Future<Map<String, dynamic>?> toggleVisibility(
    String videoId,
    bool visible,
  ) async {
    return updateVideo(videoId: videoId, visibleToUser: visible);
  }

  /// Delete a specific video by ID
  Future<bool> deleteVideo(String videoId) async {
    try {
      final res = await _api.request(
        endPoint: '/videos/$videoId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      return res != null &&
          res.statusCode == 200 &&
          res.data['success'] == true;
    } catch (e) {
      log('VideoService.deleteVideo error: $e');
      return false;
    }
  }
}
