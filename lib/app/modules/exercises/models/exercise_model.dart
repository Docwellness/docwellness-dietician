/// One catalog exercise a dietician can assign to a patient's ExercisePlan -
/// mirrors the shape of docwellness-backend's models/Exercise.js.
class Exercise {
  final String id;
  final String name;
  final String category;
  // Metabolic equivalent of task - see backend's Exercise.js for the
  // caloriesBurned formula this feeds (met * weightKg * durationHours).
  final double met;
  // AI-estimated average seconds for one rep - see backend's Exercise.js
  // for the duration-estimate fallback this feeds when a patient logs
  // completion without entering a duration.
  final double? secondsPerRep;
  final String description;
  final List<String> instructions;
  final List<String> equipment;
  final String difficultyLevel;
  final List<String> targetMuscleGroups;
  final String image;
  final String videoUrl;
  final List<String> tags;
  // Mirrors Recipe's language/translations split - translations is keyed by
  // language name (e.g. "Hindi"), each value a {name, description,
  // instructions} map from generateExerciseTranslations on the backend.
  final List<String> language;
  final Map<String, dynamic> translations;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.met,
    this.secondsPerRep,
    this.description = '',
    this.instructions = const [],
    this.equipment = const [],
    this.difficultyLevel = 'Beginner',
    this.targetMuscleGroups = const [],
    this.image = '',
    this.videoUrl = '',
    this.tags = const [],
    this.language = const ['English'],
    this.translations = const {},
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Other',
      met: (json['met'] as num?)?.toDouble() ?? 0,
      secondsPerRep: (json['secondsPerRep'] as num?)?.toDouble(),
      description: json['description'] ?? '',
      instructions: List<String>.from(json['instructions'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      difficultyLevel: json['difficultyLevel'] ?? 'Beginner',
      targetMuscleGroups: List<String>.from(json['targetMuscleGroups'] ?? []),
      image: json['image'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      language: json['language'] != null ? List<String>.from(json['language']) : const ['English'],
      translations: json['translations'] != null ? Map<String, dynamic>.from(json['translations']) : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'met': met,
    if (secondsPerRep != null) 'secondsPerRep': secondsPerRep,
    'description': description,
    'instructions': instructions,
    'equipment': equipment,
    'difficultyLevel': difficultyLevel,
    'targetMuscleGroups': targetMuscleGroups,
    'image': image,
    'videoUrl': videoUrl,
    'tags': tags,
    'language': language,
    'translations': translations,
  };
}

/// Preview returned by ExerciseService.generateExercisePreview - an
/// AI-drafted Exercise plus a reference-only calories-burned figure for a
/// typical adult at a fixed session length (see the backend's
/// generateExercisePreview doc comment). Never persisted as-is; the
/// dietician reviews/edits before Save Exercise creates the real record.
class ExercisePreview {
  final Exercise exercise;
  final int? referenceCaloriesBurned;
  final int referenceDurationMinutes;

  ExercisePreview({
    required this.exercise,
    this.referenceCaloriesBurned,
    this.referenceDurationMinutes = 30,
  });

  factory ExercisePreview.fromJson(Map<String, dynamic> json) {
    return ExercisePreview(
      exercise: Exercise.fromJson(json),
      referenceCaloriesBurned: (json['referenceCaloriesBurned'] as num?)?.toInt(),
      referenceDurationMinutes: (json['referenceDurationMinutes'] as num?)?.toInt() ?? 30,
    );
  }
}

const List<String> exerciseCategories = [
  'Cardio',
  'Strength',
  'Flexibility',
  'Sports',
  'Other',
];

const List<String> exerciseDifficultyLevels = [
  'Beginner',
  'Intermediate',
  'Advanced',
];
