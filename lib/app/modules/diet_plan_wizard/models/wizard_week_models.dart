/// Parses GET .../weeks/:week/days' response (dietPlanController.js's
/// getWeekDays) - the typed days[] schema WITH subdocument _ids, used by
/// Step 5's Smart Recipe Cards to target a specific item for swap/scale.
class WizardDayGroup {
  final String dayGroup;
  final List<WizardMealSlot> meals;

  WizardDayGroup({required this.dayGroup, required this.meals});

  factory WizardDayGroup.fromJson(Map<String, dynamic> json) {
    return WizardDayGroup(
      dayGroup: json['dayGroup'] ?? '',
      meals: (json['meals'] as List? ?? [])
          .map((m) => WizardMealSlot.fromJson(m))
          .toList(),
    );
  }
}

class WizardMealSlot {
  final String servingTime;
  final List<WizardPlanItem> items;
  final List<WizardSupplement> supplements;

  WizardMealSlot({
    required this.servingTime,
    required this.items,
    required this.supplements,
  });

  factory WizardMealSlot.fromJson(Map<String, dynamic> json) {
    return WizardMealSlot(
      servingTime: json['servingTime'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((i) => WizardPlanItem.fromJson(i))
          .toList(),
      supplements: (json['supplements'] as List? ?? [])
          .map((s) => WizardSupplement.fromJson(s))
          .toList(),
    );
  }
}

class WizardPlanItem {
  final String itemId;
  final String recipeId;
  final String? recipeName;
  final double servingMultiplier;
  final bool locked;
  final bool isLinkedComponent;
  final Map<String, dynamic>? calculatedNutrition;
  final String? displayText;

  WizardPlanItem({
    required this.itemId,
    required this.recipeId,
    this.recipeName,
    required this.servingMultiplier,
    required this.locked,
    required this.isLinkedComponent,
    this.calculatedNutrition,
    this.displayText,
  });

  double? get calories =>
      (calculatedNutrition?['calories'] as num?)?.toDouble();

  factory WizardPlanItem.fromJson(Map<String, dynamic> json) {
    return WizardPlanItem(
      itemId: json['itemId'] ?? '',
      recipeId: json['recipeId'] ?? '',
      recipeName: json['recipeName'],
      servingMultiplier: (json['servingMultiplier'] as num?)?.toDouble() ?? 1,
      locked: json['locked'] == true,
      isLinkedComponent: json['isLinkedComponent'] == true,
      calculatedNutrition: json['calculatedNutrition'] as Map<String, dynamic>?,
      displayText: json['displayText'],
    );
  }
}

class WizardSupplement {
  final String supplementId;
  final String? supplementName;
  final String? dosage;
  final String? instructions;
  final String timingAnchor;

  WizardSupplement({
    required this.supplementId,
    this.supplementName,
    this.dosage,
    this.instructions,
    required this.timingAnchor,
  });

  factory WizardSupplement.fromJson(Map<String, dynamic> json) {
    return WizardSupplement(
      supplementId: json['supplementId'] ?? '',
      supplementName: json['supplementName'],
      dosage: json['dosage'],
      instructions: json['instructions'],
      timingAnchor: json['timingAnchor'] ?? 'with',
    );
  }
}

/// Parses GET .../weeks/:week/exceptions' response.
class WizardCalorieException {
  final String dayGroup;
  final double actualCalories;
  final double targetCalories;
  final double deviationPercent;
  final double? suggestedScaleForUnlocked;

  WizardCalorieException({
    required this.dayGroup,
    required this.actualCalories,
    required this.targetCalories,
    required this.deviationPercent,
    this.suggestedScaleForUnlocked,
  });

  factory WizardCalorieException.fromJson(Map<String, dynamic> json) {
    return WizardCalorieException(
      dayGroup: json['dayGroup'] ?? '',
      actualCalories: (json['actualCalories'] as num?)?.toDouble() ?? 0,
      targetCalories: (json['targetCalories'] as num?)?.toDouble() ?? 0,
      deviationPercent: (json['deviationPercent'] as num?)?.toDouble() ?? 0,
      suggestedScaleForUnlocked:
          (json['suggestedScaleForUnlocked'] as num?)?.toDouble(),
    );
  }
}

// ============================================================
// v4.0: Ingredient-Level Portioning + Recipe Versioning models.
// A clean parallel set to WizardPlanItem/WizardDayGroup above rather than
// extending them - the JSON shapes are genuinely different (no
// servingMultiplier here at all; a full joined RecipeVersion with
// ingredients/steps instead of a flat recipeName/calories), and every
// v4.0 caller already knows it's on this path (gated by
// DietPlan.dataModel == 'plan-item'), so there's no benefit to forcing one
// model class to serve both shapes via nullable fields.
// ============================================================

/// One line in a RecipeVersion.ingredients[] - parses GET .../plan-items'
/// joined foodItemName alongside the raw foodItemId/rawQuantity/unit, and
/// serializes back (toJson) for POST .../create-custom-version's payload.
class WizardIngredientLine {
  final String foodItemId;
  final String? foodItemName;
  final double rawQuantity;
  final String unit;
  final String? preparation;

  /// 'core' | 'sub' (recipe-core-ingredient-scaling) - which ingredient(s)
  /// are the clinically/portion-meaningful ones a dietician actually
  /// adjusts ('core', e.g. Chapati's Whole Wheat Flour, or every vegetable
  /// in a Mixed Vegetable dish together) vs. ones only meaningful relative
  /// to that group ('sub' - water/salt/oil/spices). Defaults to 'sub' when
  /// absent, matching the backend schema's own default and its "not yet
  /// migrated" treatment of legacy recipes (see ingredient_editor_sheet.dart's
  /// _coreScaleRatio, which naturally becomes a no-op when no ingredient
  /// is 'core'). Deliberately NOT sent back in [toJson] - the server
  /// always derives/recomputes it itself from the version being edited
  /// (services/recipeVersioningService.js's createCustomVersion never
  /// trusts a client-submitted role), matching this class's existing
  /// convention of only sending what the server actually reads
  /// ([foodItemName]/[resolvedGramsPerUnit]/[per100gCalories] are display-only too).
  final String role;

  /// Per-100g calories, joined in by GET .../plan-items for a client-side
  /// LIVE preview only (widgets/ingredient_editor_sheet.dart) - the
  /// authoritative recompute always happens server-side in
  /// services/recipeVersioningService.js at Save time.
  final double? per100gCalories;

  /// Grams-equivalent of exactly ONE unit of [unit] (e.g. 40 for a 'piece'
  /// of Chapati) - computed server-side the same way createCustomVersion
  /// resolves nutrition (recipeVersioningService.js's resolveGramsForIngredient),
  /// since the server never sends the raw unitConversions/density map
  /// itself. Combined with [per100gCalories], this lets the editor show a
  /// live calorie figure for ANY unit, not just 'g' - null when
  /// unresolvable (no FoodItem, or no known conversion for this unit), so
  /// the editor shows "—" instead of a wrong number. Only valid for the
  /// unit this was resolved for - see copyWith, which re-resolves it from
  /// [gramsPerUnitByUnit] on a unit change rather than nulling it out.
  final double? resolvedGramsPerUnit;

  /// The SAME grams-per-unit figure as [resolvedGramsPerUnit], precomputed
  /// server-side for every unit this ingredient's FoodItem could actually
  /// resolve (not just its current one) - e.g. {"g":1,"tsp":5.15,"tbsp":15.45}
  /// for an ingredient with a known density. Lets copyWith recompute a live
  /// calorie figure the instant a dietician switches an ingredient's unit,
  /// instead of the previous "switching a unit loses the calorie figure
  /// until Save" behavior - a unit simply absent from this map means it's
  /// still genuinely unresolvable for this ingredient (never a guessed
  /// number, same convention as [resolvedGramsPerUnit] being null).
  /// Display-only, like every other joined-in field here - never sent back
  /// in [toJson].
  final Map<String, double> gramsPerUnitByUnit;

  WizardIngredientLine({
    required this.foodItemId,
    this.foodItemName,
    required this.rawQuantity,
    required this.unit,
    this.preparation,
    this.role = 'sub',
    this.per100gCalories,
    this.resolvedGramsPerUnit,
    this.gramsPerUnitByUnit = const {},
  });

  /// Changing [unit] re-resolves [resolvedGramsPerUnit] from
  /// [gramsPerUnitByUnit] (the old unit's figure was only ever valid for
  /// that unit) - falls back to null, same as before, when the newly-picked
  /// unit isn't in the map (genuinely unresolvable for this ingredient).
  WizardIngredientLine copyWith({double? rawQuantity, String? unit}) => WizardIngredientLine(
    foodItemId: foodItemId,
    foodItemName: foodItemName,
    rawQuantity: rawQuantity ?? this.rawQuantity,
    unit: unit ?? this.unit,
    preparation: preparation,
    role: role,
    per100gCalories: per100gCalories,
    resolvedGramsPerUnit: (unit == null || unit == this.unit) ? resolvedGramsPerUnit : gramsPerUnitByUnit[unit],
    gramsPerUnitByUnit: gramsPerUnitByUnit,
  );

  factory WizardIngredientLine.fromJson(Map<String, dynamic> json) {
    return WizardIngredientLine(
      foodItemId: json['foodItemId']?.toString() ?? '',
      foodItemName: json['foodItemName'],
      rawQuantity: (json['rawQuantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? 'g',
      preparation: json['preparation'],
      role: json['role'] == 'core' ? 'core' : 'sub',
      per100gCalories: (json['nutritionPer100g']?['calories'] as num?)?.toDouble(),
      resolvedGramsPerUnit: (json['resolvedGramsPerUnit'] as num?)?.toDouble(),
      gramsPerUnitByUnit: (json['gramsPerUnitByUnit'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'foodItemId': foodItemId,
    'rawQuantity': rawQuantity,
    'unit': unit,
    if (preparation != null) 'preparation': preparation,
  };
}

/// Parses a RecipeVersion object as embedded in GET .../plan-items' items[],
/// or returned directly by POST .../create-custom-version /.../auto-balance.
/// The real-world serving-unit measurement of a WHOLE dish (e.g. "Palak
/// Paratha" -> {label:'Palak Paratha', quantity:2, unit:'piece'}) - distinct
/// from WizardIngredientLine (the raw food items IN the dish). Mirrors
/// RecipeVersion.components on the backend, which is copied from the parent
/// Recipe at V1 creation and proportionally rescaled whenever ingredients
/// are edited/auto-balanced.
class WizardComponent {
  final String label;
  final double quantity;
  final String unit;

  WizardComponent({required this.label, required this.quantity, required this.unit});

  factory WizardComponent.fromJson(Map<String, dynamic> json) {
    return WizardComponent(
      label: json['label'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

class WizardRecipeVersion {
  final String id;
  final String parentRecipeId;
  final String name;
  final int versionNumber;
  final List<WizardIngredientLine> ingredients;
  final List<String> steps;
  final List<WizardComponent> components;
  final Map<String, dynamic>? nutritionPerServing;
  final bool hasUnresolvedIngredients;

  WizardRecipeVersion({
    required this.id,
    required this.parentRecipeId,
    required this.name,
    required this.versionNumber,
    required this.ingredients,
    required this.steps,
    this.components = const [],
    this.nutritionPerServing,
    required this.hasUnresolvedIngredients,
  });

  double? get calories => (nutritionPerServing?['calories'] as num?)?.toDouble();

  factory WizardRecipeVersion.fromJson(Map<String, dynamic> json) {
    return WizardRecipeVersion(
      id: json['_id']?.toString() ?? '',
      parentRecipeId: json['parentRecipeId']?.toString() ?? '',
      name: json['name'] ?? '',
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
      ingredients: (json['ingredients'] as List? ?? [])
          .map((i) => WizardIngredientLine.fromJson(i))
          .toList(),
      steps: List<String>.from(json['steps'] ?? []),
      components: (json['components'] as List? ?? [])
          .map((c) => WizardComponent.fromJson(c))
          .toList(),
      nutritionPerServing: json['nutritionPerServing'] as Map<String, dynamic>?,
      hasUnresolvedIngredients: json['hasUnresolvedIngredients'] == true,
    );
  }
}

/// One item in GET .../plan-items' meals[].items[] - the v4.0 equivalent of
/// WizardPlanItem, pointing at a full RecipeVersion instead of a
/// recipeId+servingMultiplier.
class WizardPlanItemV2 {
  final String id;
  final String recipeVersionId;
  final WizardRecipeVersion? recipeVersion;
  final bool locked;
  final Map<String, dynamic>? calculatedNutrition;
  final bool isLinkedComponent;

  WizardPlanItemV2({
    required this.id,
    required this.recipeVersionId,
    this.recipeVersion,
    required this.locked,
    this.calculatedNutrition,
    required this.isLinkedComponent,
  });

  double? get calories => (calculatedNutrition?['calories'] as num?)?.toDouble();
  String get recipeName => recipeVersion?.name ?? recipeVersionId;
  String get parentRecipeId => recipeVersion?.parentRecipeId ?? '';

  factory WizardPlanItemV2.fromJson(Map<String, dynamic> json) {
    return WizardPlanItemV2(
      id: json['_id']?.toString() ?? '',
      recipeVersionId: json['recipeVersionId']?.toString() ?? '',
      recipeVersion: json['recipeVersion'] != null ? WizardRecipeVersion.fromJson(json['recipeVersion']) : null,
      locked: json['locked'] == true,
      calculatedNutrition: json['calculatedNutrition'] as Map<String, dynamic>?,
      isLinkedComponent: json['isLinkedComponent'] == true,
    );
  }
}

/// One entry in GET .../plan-items' days[].meals[] - the v4.0 equivalent of
/// WizardMealSlot.
class WizardMealSlotV2 {
  final String servingTime;
  final String? mealSlotId;
  final List<WizardPlanItemV2> items;
  final List<WizardSupplement> supplements;

  WizardMealSlotV2({
    required this.servingTime,
    this.mealSlotId,
    required this.items,
    required this.supplements,
  });

  factory WizardMealSlotV2.fromJson(Map<String, dynamic> json) {
    return WizardMealSlotV2(
      servingTime: json['servingTime'] ?? '',
      mealSlotId: json['mealSlotId']?.toString(),
      items: (json['items'] as List? ?? []).map((i) => WizardPlanItemV2.fromJson(i)).toList(),
      supplements: (json['supplements'] as List? ?? []).map((s) => WizardSupplement.fromJson(s)).toList(),
    );
  }
}

/// Parses GET .../plan-items' days[] - the v4.0 equivalent of WizardDayGroup.
class WizardDayGroupV2 {
  final String dayGroup;
  final String? dayPlanId;
  final List<WizardMealSlotV2> meals;

  WizardDayGroupV2({required this.dayGroup, this.dayPlanId, required this.meals});

  /// Sum of every plan item's calories across every meal slot this day -
  /// deliberately excludes meal.supplements (SupplementItem.excludeFromCalories
  /// on the backend), matching services/planActivationService.js's own
  /// computeDayCalorieTotal so this mirrors the server-side +/-5% activation
  /// check exactly.
  double get totalCalories =>
      meals.expand((meal) => meal.items).fold(0.0, (sum, item) => sum + (item.calories ?? 0));

  /// True only when at least one item has been generated for this day - a
  /// day with nothing yet has nothing to validate (same "excluded rather
  /// than counted as a failure" rule as the backend).
  bool get hasItems => meals.any((meal) => meal.items.isNotEmpty);

  factory WizardDayGroupV2.fromJson(Map<String, dynamic> json) {
    return WizardDayGroupV2(
      dayGroup: json['dayGroup'] ?? '',
      dayPlanId: json['dayPlanId']?.toString(),
      meals: (json['meals'] as List? ?? []).map((m) => WizardMealSlotV2.fromJson(m)).toList(),
    );
  }
}
