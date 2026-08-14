import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class ExerciseService {
  final ApiService _apiService = ApiService();

  /// GET /api/dietician/exercises
  Future<List<Exercise>> listExercises({String? category}) async {
    try {
      final response = await _apiService.request(
        endPoint: '/exercises',
        method: 'GET',
        queryParameters: category != null && category != 'All' ? {'category': category} : null,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return list.map((e) => Exercise.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('❌ listExercises exception: $e');
      return [];
    }
  }

  /// POST /api/dietician/exercises/ai-generate-preview
  Future<ExercisePreview?> generateExercisePreview({
    required String name,
    String? category,
    List<String>? languages,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/exercises/ai-generate-preview',
        method: 'POST',
        data: {
          'name': name,
          if (category != null) 'category': category,
          if (languages != null && languages.isNotEmpty) 'language': languages.join(','),
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return ExercisePreview.fromJson(response.data['data']);
      }
      print('❌ generateExercisePreview failed: status=${response?.statusCode}, data=${response?.data}');
      return null;
    } catch (e) {
      print('❌ generateExercisePreview exception: $e');
      return null;
    }
  }

  /// POST /api/dietician/exercises
  Future<Exercise?> createExercise(Exercise exercise) async {
    try {
      final response = await _apiService.request(
        endPoint: '/exercises',
        method: 'POST',
        data: exercise.toJson(),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        return Exercise.fromJson(response.data['data']);
      }
      print('❌ createExercise failed: status=${response?.statusCode}, data=${response?.data}');
      return null;
    } catch (e) {
      print('❌ createExercise exception: $e');
      return null;
    }
  }

  /// PUT /api/dietician/exercises/:id
  Future<Exercise?> updateExercise(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.request(
        endPoint: '/exercises/$id',
        method: 'PUT',
        data: updates,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Exercise.fromJson(response.data['data']);
      }
      print('❌ updateExercise failed: status=${response?.statusCode}, data=${response?.data}');
      return null;
    } catch (e) {
      print('❌ updateExercise exception: $e');
      return null;
    }
  }

  /// POST /api/dietician/patients/:patientId/exercise-plans
  /// dailyExercises: [{exerciseId, durationMinutes, sets, reps, dayGroup}]
  Future<Map<String, dynamic>?> upsertExercisePlan({
    required String patientId,
    required List<Map<String, dynamic>> dailyExercises,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/patients/$patientId/exercise-plans',
        method: 'POST',
        data: {'dailyExercises': dailyExercises},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      print('❌ upsertExercisePlan failed: status=${response?.statusCode}, data=${response?.data}');
      return null;
    } catch (e) {
      print('❌ upsertExercisePlan exception: $e');
      return null;
    }
  }

  /// GET /api/dietician/patients/:patientId/exercise-plans/current
  /// Returns the patient's one evergreen exercise plan (raw JSON, including
  /// dailyExercises with each entry's exerciseId populated to a full
  /// Exercise object) or null if nothing has been assigned yet.
  Future<Map<String, dynamic>?> getCurrentExercisePlan(String patientId) async {
    try {
      final response = await _apiService.request(
        endPoint: '/patients/$patientId/exercise-plans/current',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true &&
          response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      print('❌ getCurrentExercisePlan exception: $e');
      return null;
    }
  }

  /// POST /api/dietician/patients/:patientId/exercise-plans/:id/activate
  Future<bool> activateExercisePlan({
    required String patientId,
    required String exercisePlanId,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/patients/$patientId/exercise-plans/$exercisePlanId/activate',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
      );
      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      print('❌ activateExercisePlan exception: $e');
      return false;
    }
  }

  /// POST /api/dietician/uploads/exercise-image
  Future<String?> uploadExerciseImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.request(
        endPoint: '/uploads/exercise-image',
        method: 'POST',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']?['url']?.toString();
      }
      print('❌ uploadExerciseImage failed: status=${response?.statusCode}, data=${response?.data}');
      return null;
    } catch (e) {
      print('❌ uploadExerciseImage exception: $e');
      return null;
    }
  }
}
