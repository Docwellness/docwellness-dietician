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
  // The recipe's real, independently-adjustable components (see
  // models/Recipe.js's `components` on the backend) - e.g. Idli with
  // Sambar and Chutney is 3 entries, each in its own natural unit (nos,
  // bowl, tbsp). Always at least 1 entry (never empty) - see
  // PatientsController._recipeFromOptionModel. `nutrition` above is
  // always the total for one serving, i.e. every component at its own
  // base quantity together.
  final List<RecipeComponent> components;
  // Real active-ingredient facts for a supplement (see SupplementFacts) -
  // null for every ordinary food recipe. When present, the dietician app
  // shows these instead of the (zeroed, meaningless) calorie/protein/
  // fiber/carbs/fat numbers - see FoodCard.supplementNutrientLabels.
  final SupplementFacts? supplementFacts;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.totalWeightGrams,
    required this.nutrition,
    this.servingTime = '',
    this.tags = const [],
    this.dayGroup = 'Monday',
    List<RecipeComponent>? components,
    this.supplementFacts,
  }) : components = (components == null || components.isEmpty)
           ? [RecipeComponent(label: name, quantity: 1, unit: 'g')]
           : components;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final secondary = json["secondaryComponent"] as Map<String, dynamic>?;
    final rawComponents = json["components"] as List?;
    final components = (rawComponents != null && rawComponents.isNotEmpty)
        ? rawComponents
              .map((e) => RecipeComponent.fromJson(e as Map<String, dynamic>))
              .toList()
        : [
            RecipeComponent(
              label: json["name"] ?? '',
              quantity: (json["baseServingQuantity"] as num?) ?? 1,
              unit: json["servingUnit"] ?? 'g',
            ),
            if (secondary != null)
              RecipeComponent(
                label: secondary["label"] ?? '',
                quantity: (secondary["quantity"] as num?) ?? 1,
                unit: secondary["unit"] ?? '',
              ),
          ];
    return Recipe(
      id: json["_id"] ?? '',
      name: json["name"] ?? '',
      image: json["image"] ?? '',
      totalWeightGrams: json["totalWeightGrams"] ?? 0,
      nutrition: Nutrition.fromJson(json["nutrition"] ?? {}),
      servingTime: json["servingTime"] ?? '',
      tags:
          (json["tags"] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      dayGroup: json["dayGroup"] ?? 'Monday',
      components: components,
      supplementFacts: json["supplementFacts"] != null
          ? SupplementFacts.fromJson(json["supplementFacts"])
          : null,
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
    "components": components.map((c) => c.toJson()).toList(),
    if (secondaryLabel.isNotEmpty)
      "secondaryComponent": {
        "label": secondaryLabel,
        "quantity": secondaryBaseQuantity,
        "unit": secondaryUnit,
      },
    if (supplementFacts != null) "supplementFacts": supplementFacts!.toJson(),
  };

  // --- Legacy 2-slot accessors, derived from `components` -------------
  // Kept so every existing call site (increment/decrementServings,
  // FoodCard's primary badge, etc.) keeps compiling/behaving unchanged for
  // the common 1-2 component case; new code (the per-component stepper
  // list) should read `components` directly instead.
  num get baseServingQuantity => components[0].quantity;
  String get servingUnit => components[0].unit;
  bool get hasSecondaryComponent => components.length > 1;
  String get secondaryLabel => components.length > 1 ? components[1].label : '';
  num get secondaryBaseQuantity =>
      components.length > 1 ? components[1].quantity : 1;
  String get secondaryUnit => components.length > 1 ? components[1].unit : '';

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
    servingTime: servingTime,
    tags: tags,
    dayGroup: dayGroup ?? this.dayGroup,
    components: components,
    supplementFacts: supplementFacts,
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
// RecipeComponent
// ---------------------------
/// One independently-adjustable component of a single serving of a recipe -
/// e.g. {label:'Idli', quantity:3, unit:'nos'}. See Recipe.components.
class RecipeComponent {
  final String label;
  final num quantity;
  final String unit;

  RecipeComponent({
    required this.label,
    required this.quantity,
    required this.unit,
  });

  factory RecipeComponent.fromJson(Map<String, dynamic> json) {
    return RecipeComponent(
      label: json["label"] ?? '',
      quantity: (json["quantity"] as num?) ?? 1,
      unit: json["unit"] ?? 'g',
    );
  }

  Map<String, dynamic> toJson() => {
    "label": label,
    "quantity": quantity,
    "unit": unit,
  };
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

// ---------------------------
// SupplementFacts
// ---------------------------
/// Real per-serving active-ingredient facts for a supplement recipe (see
/// models/Recipe.js's `supplementFacts`) - a vitamin/mineral tablet's
/// meaningful numbers are its ingredient amounts and %NRV, not
/// calories/protein/carbs/fats.
class SupplementFacts {
  final String brand;
  final num servingQuantity;
  final String servingUnit;
  final String servingLabel;
  final num? servingsPerContainer;
  final List<SupplementNutrient> nutrients;

  SupplementFacts({
    required this.brand,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingLabel,
    required this.servingsPerContainer,
    required this.nutrients,
  });

  factory SupplementFacts.fromJson(Map<String, dynamic> json) {
    final servingSize = json["servingSize"] as Map<String, dynamic>?;
    return SupplementFacts(
      brand: json["brand"] ?? '',
      servingQuantity: (servingSize?["quantity"] as num?) ?? 1,
      servingUnit: servingSize?["unit"] ?? '',
      servingLabel: servingSize?["label"] ?? '',
      servingsPerContainer: json["servingsPerContainer"] as num?,
      nutrients:
          (json["nutrients"] as List?)
              ?.map((e) => SupplementNutrient.fromJson(e))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    "brand": brand,
    "servingSize": {
      "quantity": servingQuantity,
      "unit": servingUnit,
      "label": servingLabel,
    },
    "servingsPerContainer": servingsPerContainer,
    "nutrients": nutrients.map((n) => n.toJson()).toList(),
  };
}

class SupplementNutrient {
  final String name;
  final num amount;
  final String unit;
  final num? percentNRV;

  SupplementNutrient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.percentNRV,
  });

  factory SupplementNutrient.fromJson(Map<String, dynamic> json) {
    return SupplementNutrient(
      name: json["name"] ?? '',
      amount: (json["amount"] as num?) ?? 0,
      unit: json["unit"] ?? '',
      percentNRV: json["percentNRV"] as num?,
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "amount": amount,
    "unit": unit,
    "percentNRV": percentNRV,
  };

  /// e.g. "Zinc 15mg · 150% NRV", or "Lutein 1500µg" when the label has no
  /// %NRV for this nutrient.
  String get displayLabel {
    final amountLabel = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    final base = '$name $amountLabel$unit';
    if (percentNRV == null) return base;
    final nrvLabel = percentNRV == percentNRV!.roundToDouble()
        ? percentNRV!.toInt().toString()
        : percentNRV.toString();
    return '$base · $nrvLabel% NRV';
  }
}
