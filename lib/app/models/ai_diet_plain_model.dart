// ---------------------------
// Diet Plan Data
// ---------------------------
class DietPlanData {
  final String dietPlanId;
  final String status;
  final List<WeekPlan> weeks;
  final Map<String, Recipe> recipes;

  DietPlanData({
    required this.dietPlanId,
    required this.status,
    required this.weeks,
    required this.recipes,
  });

  factory DietPlanData.fromJson(Map<String, dynamic> json) {
    return DietPlanData(
      dietPlanId: json["dietPlanId"] ?? '',
      status: json["status"] ?? 'Draft',
      weeks:
          (json["weeks"] as List?)?.map((e) => WeekPlan.fromJson(e)).toList() ??
          [],
      recipes:
          (json["recipes"] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Recipe.fromJson(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
    "dietPlanId": dietPlanId,
    "status": status,
    "weeks": weeks.map((e) => e.toJson()).toList(),
    "recipes": recipes.map((key, value) => MapEntry(key, value.toJson())),
  };
}

// ---------------------------
// Week
// ---------------------------
class WeekPlan {
  final int week;
  final List<DailyMeal> dailyMeals;

  WeekPlan({required this.week, required this.dailyMeals});

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    return WeekPlan(
      week: json["week"],
      dailyMeals: (json["dailyMeals"] as List)
          .map((e) => DailyMeal.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "week": week,
    "dailyMeals": dailyMeals.map((e) => e.toJson()).toList(),
  };
}

// ---------------------------
// Daily Meal
// ---------------------------
class DailyMeal {
  final String servingTime;
  final String recipeId;

  DailyMeal({required this.servingTime, required this.recipeId});

  factory DailyMeal.fromJson(Map<String, dynamic> json) {
    return DailyMeal(
      servingTime: json["servingTime"] ?? '',
      recipeId: json["recipeId"] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "servingTime": servingTime,
    "recipeId": recipeId,
  };
}

// ---------------------------
// Recipe
// ---------------------------
class Recipe {
  final String id;
  final String name;
  final String image;
  final int totalWeightGrams;
  final Nutrition nutrition;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.totalWeightGrams,
    required this.nutrition,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json["_id"] ?? '',
      name: json["name"] ?? '',
      image: json["image"] ?? '',
      totalWeightGrams: json["totalWeightGrams"] ?? 0,
      nutrition: Nutrition.fromJson(json["nutrition"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "image": image,
    "totalWeightGrams": totalWeightGrams,
    "nutrition": nutrition.toJson(),
  };
}

// ---------------------------
// Nutrition
// ---------------------------
class Nutrition {
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json["calories"] ?? 0,
      protein: json["protein"] ?? 0,
      carbs: json["carbs"] ?? 0,
      fats: json["fats"] ?? 0,
      fiber: json["fiber"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "calories": calories,
    "protein": protein,
    "carbs": carbs,
    "fats": fats,
    "fiber": fiber,
  };
}
