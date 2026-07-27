import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart'
    show SupplementFacts;

class DietPlanWeekData {
  final String dietPlanId;
  final int week;
  final WeekSummary summary;
  // One entry per day-group (Monday/Tuesday/Wednesday/Thursday - Monday's
  // meals repeat on Friday, Tuesday's on Saturday, Wednesday's on Sunday,
  // Thursday is unique). All 4 are bundled in this single response so
  // switching day-group tabs in the UI is a pure client-side filter, no
  // re-fetch needed - see buildDayGroupsOptions in dietPlanOptions.js.
  final List<DayGroupOptions> dayGroups;
  final List<String> riskFlags;
  final List<String> validationWarnings;
  // 'loss' or 'gain' - derived server-side from the patient's primaryGoal
  // (see resolveWeightTrend in dietPlanController.js). Drives the trend-
  // aware sabji/side/salad default quantities and stepper clamps. Defaults
  // to 'gain' (the less-restrictive behavior) if ever missing.
  final String weightTrend;
  // True when this week's options were built from finalizedPlan (real,
  // dietician-set servings) rather than the AI's raw generatedPlan draft
  // (which has no `servings` field at all - see dietPlanJsonSchema.js).
  // Needed to tell a genuine explicit "1" apart from the "not yet set"
  // placeholder default - see isUnexplicitDefault in patients_controller.dart.
  final bool isFinalized;

  DietPlanWeekData({
    required this.dietPlanId,
    required this.week,
    required this.summary,
    required this.dayGroups,
    this.riskFlags = const [],
    this.validationWarnings = const [],
    this.weightTrend = 'gain',
    this.isFinalized = false,
  });

  factory DietPlanWeekData.fromJson(Map<String, dynamic> json) {
    return DietPlanWeekData(
      dietPlanId: json['dietPlanId'] ?? '',
      week: json['week'] ?? 0,
      summary: WeekSummary.fromJson(json['summary'] ?? {}),
      dayGroups: (json['dayGroups'] as List<dynamic>? ?? [])
          .map((e) => DayGroupOptions.fromJson(e))
          .toList(),
      riskFlags:
          (json['riskFlags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      validationWarnings:
          (json['validationWarnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      weightTrend: json['weightTrend'] ?? 'gain',
      isFinalized: json['isFinalized'] == true,
    );
  }
}

class DayGroupOptions {
  final String dayGroup;
  final List<ServingTimeModel> servingTimes;

  DayGroupOptions({required this.dayGroup, required this.servingTimes});

  factory DayGroupOptions.fromJson(Map<String, dynamic> json) {
    return DayGroupOptions(
      dayGroup: json['dayGroup'] ?? 'Monday',
      servingTimes: (json['servingTimes'] as List<dynamic>? ?? [])
          .map((e) => ServingTimeModel.fromJson(e))
          .toList(),
    );
  }
}

class WeekSummary {
  // num, not int - these are sums of real recipe nutrition (see
  // NutritionModel's comment) and can be fractional; the draft-options
  // endpoint's summary is a live sum of selected recipes' macros, already
  // confirmed to return decimals (e.g. fatGrams: 55.3) for real data.
  final num totalCalories;
  final num fatPercent;
  final num fatGrams;
  final num carbPercent;
  final num carbGrams;
  final num proteinPercent;
  final num proteinGrams;

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
      totalCalories: (json['totalCalories'] as num?) ?? 0,
      fatPercent: (json['fatPercent'] as num?) ?? 0,
      fatGrams: (json['fatGrams'] as num?) ?? 0,
      carbPercent: (json['carbPercent'] as num?) ?? 0,
      carbGrams: (json['carbGrams'] as num?) ?? 0,
      proteinPercent: (json['proteinPercent'] as num?) ?? 0,
      proteinGrams: (json['proteinGrams'] as num?) ?? 0,
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
  // How many servings the dietician already set for this slot (only
  // meaningful when isSelected - defaults to 1, matching cleanSelectedMeals'
  // backend default for a not-yet-adjusted selection).
  final num servings;
  final List<String> tags;
  // For a handful of compound snacks (e.g. "Banana with Roasted Chana and
  // Seeds") that combine a countable fruit (servingSize/servings) with a
  // scoopable mix-in - null for every ordinary single-quantity recipe.
  final SecondaryComponentModel? secondaryComponent;
  // The persisted quantity for secondaryComponent - same "only meaningful
  // when isSelected" semantics as servings.
  final num secondaryServings;
  // The recipe's real, independently-adjustable components (see
  // models/Recipe.js's `components` on the backend) - e.g. Idli with Sambar
  // and Chutney is 3 entries, each in its own natural unit. Falls back to a
  // synthesized [servingSize, secondaryComponent] pair (below) for a recipe
  // the backend hasn't migrated yet, so this is never empty.
  final List<ComponentModel> components;
  // Per-component selected quantities (same order/length as `components`),
  // only when the dietician has actually persisted explicit per-component
  // servings for this meal - null otherwise (NOT defaulted to a sentinel
  // like `servings`/`secondaryServings` above, since a real base quantity
  // like "1 nos" would be indistinguishable from an unset sentinel). The
  // dietician app falls back to the servings/secondaryServings sentinel
  // convention for components 0/1 when this is null - see
  // patients_controller.dart's _applyDraftOptionsForWeek.
  final List<num>? componentServings;
  // Real active-ingredient facts for a supplement - see SupplementFacts in
  // ai_diet_plain_model.dart (same shape); null for ordinary food recipes.
  final SupplementFacts? supplementFacts;

  RecipeModel({
    required this.id,
    required this.name,
    required this.image,
    required this.nutrition,
    required this.servingTime,
    required this.isSelected,
    required this.nextWeekTag,
    required this.servingSize,
    this.servings = 1,
    this.tags = const [],
    this.secondaryComponent,
    this.secondaryServings = 1,
    this.components = const [],
    this.componentServings,
    this.supplementFacts,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final servingSize = ServingSizeModel.fromJson(json['servingSize'] ?? {});
    final secondaryComponent = json['secondaryComponent'] != null
        ? SecondaryComponentModel.fromJson(json['secondaryComponent'])
        : null;
    final rawComponents = json['components'] as List?;
    final components = (rawComponents != null && rawComponents.isNotEmpty)
        ? rawComponents.map((e) => ComponentModel.fromJson(e)).toList()
        : [
            ComponentModel(
              label: json['name'] ?? '',
              quantity: servingSize.quantity > 0 ? servingSize.quantity : 1,
              unit: servingSize.unit.isNotEmpty ? servingSize.unit : 'g',
            ),
            if (secondaryComponent != null)
              ComponentModel(
                label: secondaryComponent.label,
                quantity: secondaryComponent.quantity,
                unit: secondaryComponent.unit,
              ),
          ];
    return RecipeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      nutrition: NutritionModel.fromJson(json['nutrition'] ?? {}),
      servingTime: json['servingTime'] ?? '',
      isSelected: json['isSelected'] ?? false,
      nextWeekTag: json['nextWeekTag'],
      servingSize: servingSize,
      servings: (json['servings'] as num?) ?? 1,
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      secondaryComponent: secondaryComponent,
      secondaryServings: (json['secondaryServings'] as num?) ?? 1,
      components: components,
      componentServings: (json['componentServings'] as List?)
          ?.map((e) => e as num)
          .toList(),
      supplementFacts: json['supplementFacts'] != null
          ? SupplementFacts.fromJson(json['supplementFacts'])
          : null,
    );
  }
}

/// One independently-adjustable component of a recipe's single serving -
/// e.g. {label:'Idli', quantity:3, unit:'nos'}. See RecipeModel.components.
class ComponentModel {
  final String label;
  final num quantity;
  final String unit;

  ComponentModel({
    required this.label,
    required this.quantity,
    required this.unit,
  });

  factory ComponentModel.fromJson(Map<String, dynamic> json) {
    return ComponentModel(
      label: json['label'] ?? '',
      quantity: (json['quantity'] as num?) ?? 1,
      unit: json['unit'] ?? 'g',
    );
  }
}

/// The second independently-adjustable component of a compound snack (e.g.
/// the seeds/chikki mix-in alongside a fruit) - see RecipeModel.secondaryComponent.
class SecondaryComponentModel {
  final String label;
  final num quantity;
  final String unit;

  SecondaryComponentModel({
    required this.label,
    required this.quantity,
    required this.unit,
  });

  factory SecondaryComponentModel.fromJson(Map<String, dynamic> json) {
    return SecondaryComponentModel(
      label: json['label'] ?? '',
      quantity: (json['quantity'] as num?) ?? 1,
      unit: json['unit'] ?? '',
    );
  }
}

class ServingSizeModel {
  // num, not int - same reasoning as NutritionModel's toInt() below: a
  // fractional servingSize (e.g. 0.5 cup) would otherwise throw a runtime
  // TypeError assigning a double JSON value into an int field.
  final num quantity;
  final String unit;

  ServingSizeModel({required this.quantity, required this.unit});

  factory ServingSizeModel.fromJson(Map<String, dynamic> json) {
    return ServingSizeModel(
      quantity: (json['quantity'] as num?) ?? 0,
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
