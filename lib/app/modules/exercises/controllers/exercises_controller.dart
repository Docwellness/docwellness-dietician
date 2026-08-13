import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/modules/exercises/services/exercise_service.dart';
import 'package:get/get.dart';

class ExercisesController extends GetxController {
  final ExerciseService _service = ExerciseService();

  RxList<Exercise> exercises = <Exercise>[].obs;
  RxBool isLoading = false.obs;
  RxString selectedCategory = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    isLoading.value = true;
    exercises.value = await _service.listExercises(category: selectedCategory.value);
    isLoading.value = false;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    fetchExercises();
  }

  Future<Exercise?> createExercise(Exercise exercise) async {
    final created = await _service.createExercise(exercise);
    if (created != null) {
      exercises.insert(0, created);
    }
    return created;
  }

  Future<ExercisePreview?> generateExercisePreview({required String name, String? category, List<String>? languages}) =>
      _service.generateExercisePreview(name: name, category: category, languages: languages);

  Future<Exercise?> updateExercise(String id, Map<String, dynamic> updates) async {
    final updated = await _service.updateExercise(id, updates);
    if (updated != null) {
      final index = exercises.indexWhere((e) => e.id == id);
      if (index != -1) exercises[index] = updated;
    }
    return updated;
  }

  Future<String?> uploadExerciseImage(String filePath) => _service.uploadExerciseImage(filePath);
}
