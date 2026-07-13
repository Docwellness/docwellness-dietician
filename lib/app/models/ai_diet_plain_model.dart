// ---------------------------
// Diet Plan Data
// ---------------------------
class DietPlanData {
  final String dietPlanId;
  final String status;
  final List<WeekPlan> weeks;
  final Map<String, Recipe> recipes;
  final List<String> riskFlags;
  final List<String> validationWarnings;

  DietPlanData({
    required this.dietPlanId,
    required this.status,
    required this.weeks,
    required this.recipes,
    this.riskFlags = const [],
    this.validationWarnings = const [],
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
      riskFlags:
          (json["riskFlags"] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      validationWarnings:
          (json["validationWarnings"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    "dietPlanId": dietPlanId,
    "status": status,
    "weeks": weeks.map((e) => e.toJson()).toList(),
    "recipes": recipes.map((key, value) => MapEntry(key, value.toJson())),
    "riskFlags": riskFlags,
    "validationWarnings": validationWarnings,
  };
}

/// Human-readable copy for each backend risk-flag code, for banner display.
String describeRiskFlag(String flag) {
  switch (flag) {
    case 'isMinor':
      return 'Patient is a minor - confirm this plan with a pediatrician/sports dietitian before activating.';
    case 'highProteinForWeight':
      return 'Requested protein target exceeds the standard recommended range for this patient\'s bodyweight.';
    case 'minorOnHighProteinPlan':
      return 'High-protein plan for a minor - please review energy availability and confirm with a specialist before activating.';
    default:
      return flag;
  }
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
  // The recipe's own base serving (e.g. Chole = 350g, Chapati = 1 piece) -
  // the "1x" reference point the servings +/- stepper adjusts away from.
  // `nutrition` above is always per this base serving.
  final num baseServingQuantity;
  final String servingUnit;
  // Which meal slot this recipe was selected under - needed so
  // buildFinalizeWeekPayload can build {servingTime, recipeId} entries
  // straight from weekSelectedRecipes (a recipe never carried its own
  // servingTime before the multi-option-per-slot options pool existed).
  final String servingTime;
  // e.g. ['side'], ['salad'] - drives the trend-aware default/clamp/step
  // logic (patients_controller.dart) that distinguishes a salad from a
  // sabji/curry, since both are gram-unit.
  final List<String> tags;
  // 'Monday'/'Tuesday'/'Wednesday'/'Thursday' - which day-group this
  // recipe was selected under (Monday's meals repeat on Friday, Tuesday's
  // on Saturday, Wednesday's on Sunday - Thursday is unique; see
  // dayGroups.js on the backend). Part of this recipe's identity, same
  // reasoning as servingTime below - the same recipe can be legitimately
  // selected under two different day-groups' same slot with different
  // counts.
  final String dayGroup;
  // The second independently-adjustable component of a compound snack
  // (e.g. "Banana with Roasted Chana and Seeds" - servingSize/baseServing-
  // Quantity above is the banana, this is the seeds mix-in) - see
  // patients_controller.dart's selectedSecondaryServings/increment-
  // /decrementSecondaryServings. secondaryLabel.isEmpty means "no second
  // component", true for every ordinary single-quantity recipe.
  final String secondaryLabel;
  final num secondaryBaseQuantity;
  final String secondaryUnit;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.totalWeightGrams,
    required this.nutrition,
    this.baseServingQuantity = 1,
    this.servingUnit = 'g',
    this.servingTime = '',
    this.tags = const [],
    this.dayGroup = 'Monday',
    this.secondaryLabel = '',
    this.secondaryBaseQuantity = 1,
    this.secondaryUnit = '',
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final secondary = json["secondaryComponent"] as Map<String, dynamic>?;
    return Recipe(
      id: json["_id"] ?? '',
      name: json["name"] ?? '',
      image: json["image"] ?? '',
      totalWeightGrams: json["totalWeightGrams"] ?? 0,
      nutrition: Nutrition.fromJson(json["nutrition"] ?? {}),
      baseServingQuantity: (json["baseServingQuantity"] as num?) ?? 1,
      servingUnit: json["servingUnit"] ?? 'g',
      servingTime: json["servingTime"] ?? '',
      tags:
          (json["tags"] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      dayGroup: json["dayGroup"] ?? 'Monday',
      secondaryLabel: secondary?["label"] ?? '',
      secondaryBaseQuantity: (secondary?["quantity"] as num?) ?? 1,
      secondaryUnit: secondary?["unit"] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "image": image,
    "totalWeightGrams": totalWeightGrams,
    "nutrition": nutrition.toJson(),
    "baseServingQuantity": baseServingQuantity,
    "servingUnit": servingUnit,
    "servingTime": servingTime,
    "tags": tags,
    "dayGroup": dayGroup,
    if (secondaryLabel.isNotEmpty)
      "secondaryComponent": {
        "label": secondaryLabel,
        "quantity": secondaryBaseQuantity,
        "unit": secondaryUnit,
      },
  };

  bool get hasSecondaryComponent => secondaryLabel.isNotEmpty;

  /// A copy under a different day-group - used for supplements, which are
  /// meant to be identical across all 4 day-groups (see toggleMealSelection
  /// in patients_controller.dart), so selecting/deselecting one needs to
  /// produce/remove the same recipe under every group.
  Recipe copyWith({String? dayGroup}) => Recipe(
    id: id,
    name: name,
    image: image,
    totalWeightGrams: totalWeightGrams,
    nutrition: nutrition,
    baseServingQuantity: baseServingQuantity,
    servingUnit: servingUnit,
    servingTime: servingTime,
    tags: tags,
    dayGroup: dayGroup ?? this.dayGroup,
    secondaryLabel: secondaryLabel,
    secondaryBaseQuantity: secondaryBaseQuantity,
    secondaryUnit: secondaryUnit,
  );

  // Identity by id + servingTime + dayGroup - callers (e.g.
  // select_diet_sheet.dart's `selectedRecipesForWeek.contains(recipe)`
  // isSelected check) need two Recipe instances representing the same
  // underlying recipe *in the same slot and day-group* to compare equal
  // even if they were constructed separately (e.g. once when seeding
  // default selections, once when building the options list for a tab).
  // Both servingTime and dayGroup are part of the key (not id alone)
  // because the same recipe can be legitimately selected in two different
  // slots/day-groups in the same week with different counts (e.g. 3
  // chapatis at Monday-group's Lunch, 2 at Tuesday-group's Lunch) - those
  // must be tracked independently, not merged.
  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.id == id &&
      other.servingTime == servingTime &&
      other.dayGroup == dayGroup;

  @override
  int get hashCode => Object.hash(id, servingTime, dayGroup);
}

// ---------------------------
// Nutrition
// ---------------------------
class Nutrition {
  // num, not int - recipe nutrition values can be fractional (e.g.
  // "Flaxseed Water" has protein: 1.9, fats: 4.3). Backend JSON sends
  // whatever numeric type Mongo stored, and assigning a double into an
  // int-typed field throws a runtime TypeError in Dart - `?? 0` only
  // guards against null, not a type mismatch, so this was crashing the
  // *entire* DietPlanData.fromJson parse (silently swallowed by the
  // caller's try/catch) any time a plan included a recipe with decimal
  // nutrition, leaving the UI showing stale/empty data.
  final num calories;
  final num protein;
  final num carbs;
  final num fats;
  final num fiber;

  Nutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: (json["calories"] as num?) ?? 0,
      protein: (json["protein"] as num?) ?? 0,
      carbs: (json["carbs"] as num?) ?? 0,
      fats: (json["fats"] as num?) ?? 0,
      fiber: (json["fiber"] as num?) ?? 0,
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
