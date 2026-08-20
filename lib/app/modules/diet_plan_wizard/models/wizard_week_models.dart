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

/// Parses GET .../weeks/:week/swap-alternatives' response entries.
class WizardSwapAlternative {
  final String id;
  final String name;
  final double? calories;

  WizardSwapAlternative({required this.id, required this.name, this.calories});

  factory WizardSwapAlternative.fromJson(Map<String, dynamic> json) {
    return WizardSwapAlternative(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      calories: (json['calories'] as num?)?.toDouble(),
    );
  }
}
