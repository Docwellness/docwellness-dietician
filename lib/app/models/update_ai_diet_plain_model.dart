class DietPlanWeekData {
  final String dietPlanId;
  final int week;
  final WeekSummary summary;
  final List<ServingTimeModel> servingTimes;

  DietPlanWeekData({
    required this.dietPlanId,
    required this.week,
    required this.summary,
    required this.servingTimes,
  });

  factory DietPlanWeekData.fromJson(Map<String, dynamic> json) {
    return DietPlanWeekData(
      dietPlanId: json['dietPlanId'] ?? '',
      week: json['week'] ?? 0,
      summary: WeekSummary.fromJson(json['summary'] ?? {}),
      servingTimes: (json['servingTimes'] as List<dynamic>? ?? [])
          .map((e) => ServingTimeModel.fromJson(e))
          .toList(),
    );
  }
}

class WeekSummary {
  final int totalCalories;
  final int fatPercent;
  final int fatGrams;
  final int carbPercent;
  final int carbGrams;
  final int proteinPercent;
  final int proteinGrams;

  WeekSummary({
    required this.totalCalories,
    required this.fatPercent,
    required this.fatGrams,
    required this.carbPercent,
    required this.carbGrams,
    required this.proteinPercent,
    required this.proteinGrams,
  });

  factory WeekSummary.fromJson(Map<String, dynamic> json) {
    return WeekSummary(
      totalCalories: json['totalCalories'] ?? 0,
      fatPercent: json['fatPercent'] ?? 0,
      fatGrams: json['fatGrams'] ?? 0,
      carbPercent: json['carbPercent'] ?? 0,
      carbGrams: json['carbGrams'] ?? 0,
      proteinPercent: json['proteinPercent'] ?? 0,
      proteinGrams: json['proteinGrams'] ?? 0,
    );
  }
}

class ServingTimeModel {
  final String servingTime;
  final String selectedRecipeId;
  final List<RecipeModel> recipes;

  ServingTimeModel({
    required this.servingTime,
    required this.selectedRecipeId,
    required this.recipes,
  });

  factory ServingTimeModel.fromJson(Map<String, dynamic> json) {
    return ServingTimeModel(
      servingTime: json['servingTime'] ?? '',
      selectedRecipeId: json['selectedRecipeId'] ?? '',
      recipes: (json['recipes'] as List<dynamic>? ?? [])
          .map((e) => RecipeModel.fromJson(e))
          .toList(),
    );
  }
}

class RecipeModel {
  final String id;
  final String name;
  final String image;
  final NutritionModel nutrition;
  final String servingTime;
  bool isSelected;
  final String? nextWeekTag;
  final ServingSizeModel servingSize;

  RecipeModel({
    required this.id,
    required this.name,
    required this.image,
    required this.nutrition,
    required this.servingTime,
    required this.isSelected,
    required this.nextWeekTag,
    required this.servingSize,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      nutrition: NutritionModel.fromJson(json['nutrition'] ?? {}),
      servingTime: json['servingTime'] ?? '',
      isSelected: json['isSelected'] ?? false,
      nextWeekTag: json['nextWeekTag'],
      servingSize: ServingSizeModel.fromJson(json['servingSize'] ?? {}),
    );
  }
}

class ServingSizeModel {
  final int quantity;
  final String unit;

  ServingSizeModel({required this.quantity, required this.unit});

  factory ServingSizeModel.fromJson(Map<String, dynamic> json) {
    return ServingSizeModel(
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

class NutritionModel {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;

  NutritionModel({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) =>
        (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);
    return NutritionModel(
      calories: toInt(json['calories']),
      protein: toInt(json['protein']),
      carbs: toInt(json['carbs']),
      fats: toInt(json['fats']),
      fiber: toInt(json['fiber']),
    );
  }
}
