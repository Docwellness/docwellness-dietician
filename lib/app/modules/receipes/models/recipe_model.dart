import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart'
    show SupplementFacts;

/// Recipe model for AI-generated recipe preview response
class RecipePreview {
  final String? id;
  final String name;
  final String? image;
  final String description;
  final String category;
  final String cuisine;
  final String servingTime;
  final int servings;
  final int? preparationTime;
  final int? cookingTime;
  final DietaryHabits dietaryHabits;
  final FreeFrom freeFrom;
  final List<Ingredient> ingredients;
  final ServingSize servingSize;
  final Nutrition nutrition;
  final List<String> cookingSteps;
  final List<String> warnings;
  final List<String> languages;
  final Map<String, RecipeTranslation> translations;
  // Real active-ingredient facts for a category:'Supplements' recipe - see
  // SupplementFacts (shared with the diet-plan selection flow). Null for
  // every ordinary food recipe.
  final SupplementFacts? supplementFacts;
  // The recipe's real, independently-adjustable components (see
  // models/Recipe.js's `components` on the backend) - e.g. Idli with
  // Sambar and Chutney is 3 entries, each in its own natural unit (nos,
  // bowl, tbsp). Always at least one entry - see the fallback in fromJson.
  // This is what EditComponentsSheet edits and what the dietician-facing
  // diet-plan stepper (patients_controller.dart) ultimately steps through.
  final List<RecipeComponent> components;

  RecipePreview({
    this.id,
    required this.name,
    this.image,
    required this.description,
    required this.category,
    required this.cuisine,
    required this.servingTime,
    required this.servings,
    this.preparationTime,
    this.cookingTime,
    required this.dietaryHabits,
    required this.freeFrom,
    required this.ingredients,
    required this.servingSize,
    required this.nutrition,
    required this.cookingSteps,
    required this.warnings,
    this.languages = const ['English'],
    this.translations = const {},
    this.supplementFacts,
    List<RecipeComponent>? components,
  }) : components = (components == null || components.isEmpty)
           ? [
               RecipeComponent(
                 label: name,
                 quantity: servingSize.quantity ?? 1,
                 unit: servingSize.unit ?? 'g',
               ),
             ]
           : components;

  factory RecipePreview.fromJson(Map<String, dynamic> json) {
    // Parse language field - can be a string or list
    List<String> parsedLanguages;
    if (json['language'] is List) {
      parsedLanguages = List<String>.from(json['language']);
    } else if (json['language'] is String && json['language'] != null) {
      parsedLanguages = (json['language'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else {
      parsedLanguages = ['English'];
    }

    // Parse translations map
    Map<String, RecipeTranslation> parsedTranslations = {};
    if (json['translations'] is Map) {
      (json['translations'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedTranslations[key.toString()] = RecipeTranslation.fromJson(
            value,
          );
        }
      });
    }

    return RecipePreview(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: json['name'] ?? '',
      image: json['image'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'Indian',
      cuisine: json['cuisine'] ?? 'Indian',
      servingTime: json['servingTime'] ?? '',
      servings: json['servings'] ?? 1,
      preparationTime: json['preparationTime'],
      cookingTime: json['cookingTime'],
      dietaryHabits: DietaryHabits.fromJson(json['dietaryHabits'] ?? {}),
      freeFrom: FreeFrom.fromJson(json['freeFrom'] ?? {}),
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e))
              .toList() ??
          [],
      servingSize: ServingSize.fromJson(json['servingSize'] ?? {}),
      nutrition: Nutrition.fromJson(json['nutrition'] ?? {}),
      cookingSteps: List<String>.from(json['cookingSteps'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      languages: parsedLanguages,
      translations: parsedTranslations,
      supplementFacts: json['supplementFacts'] != null
          ? SupplementFacts.fromJson(json['supplementFacts'])
          : null,
      components: (json['components'] as List<dynamic>?)
          ?.map((e) => RecipeComponent.fromJson(e))
          .toList(),
    );
  }

  /// Returns a copy with [id] overridden - used when an endpoint (e.g.
  /// ai-update-from-edits) returns a refined preview with no `id` of its
  /// own, so the caller's already-known recipe id isn't lost.
  RecipePreview copyWithId(String? newId) {
    return RecipePreview(
      id: newId,
      name: name,
      image: image,
      description: description,
      category: category,
      cuisine: cuisine,
      servingTime: servingTime,
      servings: servings,
      preparationTime: preparationTime,
      cookingTime: cookingTime,
      dietaryHabits: dietaryHabits,
      freeFrom: freeFrom,
      ingredients: ingredients,
      servingSize: servingSize,
      nutrition: nutrition,
      cookingSteps: cookingSteps,
      warnings: warnings,
      languages: languages,
      translations: translations,
      supplementFacts: supplementFacts,
      components: components,
    );
  }

  /// Returns a copy with [components] and [nutrition] both overridden -
  /// used by EditComponentsSheet to write back the dietician's edits,
  /// together with a recomputed nutrition so calories/macros don't stay
  /// frozen at whatever the AI originally generated once a part's quantity
  /// changes - see [scaleNutritionForComponentEdit]. Also carries each
  /// edited component's new quantity/unit onto the matching ingredient (by
  /// name) - components and ingredients used to be two entirely independent
  /// lists, so editing "Brown Bread" to 2 slices via Edit Portions left the
  /// Ingredients tab's own "Brown Bread" row silently showing its old,
  /// un-synced quantity. Best-effort: a component with no same-named
  /// ingredient (e.g. one recipe part built from several ingredients) is
  /// simply not reflected in the ingredient list, same as before.
  RecipePreview copyWithComponentsAndNutrition(
    List<RecipeComponent> newComponents,
    Nutrition newNutrition,
  ) {
    return RecipePreview(
      id: id,
      name: name,
      image: image,
      description: description,
      category: category,
      cuisine: cuisine,
      servingTime: servingTime,
      servings: servings,
      preparationTime: preparationTime,
      cookingTime: cookingTime,
      dietaryHabits: dietaryHabits,
      freeFrom: freeFrom,
      ingredients: _syncedIngredients(ingredients, newComponents),
      servingSize: servingSize,
      nutrition: newNutrition,
      cookingSteps: cookingSteps,
      warnings: warnings,
      languages: languages,
      translations: translations,
      supplementFacts: supplementFacts,
      components: newComponents,
    );
  }

  static List<Ingredient> _syncedIngredients(
    List<Ingredient> ingredients,
    List<RecipeComponent> components,
  ) {
    return ingredients.map((ingredient) {
      RecipeComponent? match;
      for (final c in components) {
        if (c.label.trim().toLowerCase() == ingredient.name.trim().toLowerCase()) {
          match = c;
          break;
        }
      }
      if (match == null) return ingredient;
      return ingredient.copyWith(quantity: match.quantity, unit: match.unit);
    }).toList();
  }

  /// Scales [nutrition] by how much each component's quantity changed,
  /// without any AI call - deterministic and instant. Mirrors the same
  /// approximation already used diet-plan-side to scale a recipe's
  /// nutrition for a dietician's servings adjustment (see
  /// PatientsController._nutritionScaleRatio / weekNutritionSummary.js's
  /// computeMealRatio): the scale factor is the average, across every
  /// component present both before and after the edit, of (new quantity /
  /// old quantity) - e.g. doubling just the Idli count in a 3-part dish
  /// nudges calories up by roughly a third, not the full 2x, since Sambar
  /// and Chutney didn't change. A newly-added part (no "before" quantity
  /// to compare against) doesn't contribute a ratio - there's nothing to
  /// scale for it, only existing parts being adjusted moves the number.
  /// Never fabricates precision the ingredient list doesn't have, same
  /// honesty tradeoff as the diet-plan-side version.
  static Nutrition scaleNutritionForComponentEdit({
    required List<RecipeComponent> oldComponents,
    required List<RecipeComponent> newComponents,
    required Nutrition baseNutrition,
  }) {
    final ratios = <num>[];
    for (var i = 0; i < newComponents.length && i < oldComponents.length; i++) {
      final oldQty = oldComponents[i].quantity;
      if (oldQty <= 0) continue;
      ratios.add(newComponents[i].quantity / oldQty);
    }
    if (ratios.isEmpty) return baseNutrition;
    final scale = ratios.reduce((a, b) => a + b) / ratios.length;
    num scaled(num? value) => value == null ? 0 : value * scale;
    return Nutrition(
      calories: scaled(baseNutrition.calories),
      protein: scaled(baseNutrition.protein),
      carbs: scaled(baseNutrition.carbs),
      fats: scaled(baseNutrition.fats),
      fiber: scaled(baseNutrition.fiber),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'image': image,
      'description': description,
      'category': category,
      'cuisine': cuisine,
      'servingTime': servingTime,
      'servings': servings,
      'preparationTime': preparationTime,
      'cookingTime': cookingTime,
      'dietaryHabits': dietaryHabits.toJson(),
      'freeFrom': freeFrom.toJson(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'servingSize': servingSize.toJson(),
      'nutrition': nutrition.toJson(),
      'cookingSteps': cookingSteps,
      'warnings': warnings,
      'language': languages,
      'translations': translations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (supplementFacts != null) 'supplementFacts': supplementFacts!.toJson(),
      'components': components.map((e) => e.toJson()).toList(),
    };
  }
}

/// One independently-adjustable component of a single serving of a recipe -
/// e.g. {label:'Idli', quantity:3, unit:'nos'}. See RecipePreview.components.
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
      label: json['label'] ?? '',
      quantity: (json['quantity'] as num?) ?? 1,
      unit: json['unit'] ?? 'g',
    );
  }

  RecipeComponent copyWith({String? label, num? quantity, String? unit}) {
    return RecipeComponent(
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'quantity': quantity,
    'unit': unit,
  };
}

/// Translation data for a single language
class RecipeTranslation {
  final String name;
  final String description;
  final List<IngredientTranslation> ingredients;
  final List<String> cookingSteps;
  final List<String> warnings;

  RecipeTranslation({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.cookingSteps,
    required this.warnings,
  });

  factory RecipeTranslation.fromJson(Map<String, dynamic> json) {
    return RecipeTranslation(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map(
                (e) => IngredientTranslation.fromJson(
                  e is Map<String, dynamic> ? e : {},
                ),
              )
              .toList() ??
          [],
      cookingSteps: List<String>.from(json['cookingSteps'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'cookingSteps': cookingSteps,
      'warnings': warnings,
    };
  }
}

/// Translated ingredient name and description
class IngredientTranslation {
  final String name;
  final String description;

  IngredientTranslation({required this.name, required this.description});

  factory IngredientTranslation.fromJson(Map<String, dynamic> json) {
    return IngredientTranslation(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description};
  }
}

class DietaryHabits {
  final bool vegan;
  final bool jain;
  final bool vegetarian;
  final bool nonVegetarian;
  final bool eggitarian;

  DietaryHabits({
    this.vegan = false,
    this.jain = false,
    this.vegetarian = false,
    this.nonVegetarian = false,
    this.eggitarian = false,
  });

  factory DietaryHabits.fromJson(Map<String, dynamic> json) {
    return DietaryHabits(
      vegan: json['vegan'] ?? false,
      jain: json['jain'] ?? false,
      vegetarian: json['vegetarian'] ?? false,
      nonVegetarian: json['nonVegetarian'] ?? false,
      eggitarian: json['eggitarian'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vegan': vegan,
      'jain': jain,
      'vegetarian': vegetarian,
      'nonVegetarian': nonVegetarian,
      'eggitarian': eggitarian,
    };
  }
}

class FreeFrom {
  final bool sugar;
  final bool salt;
  final bool processedFood;
  final bool oil;

  FreeFrom({
    this.sugar = false,
    this.salt = false,
    this.processedFood = false,
    this.oil = false,
  });

  factory FreeFrom.fromJson(Map<String, dynamic> json) {
    return FreeFrom(
      sugar: json['sugar'] ?? false,
      salt: json['salt'] ?? false,
      processedFood: json['processedFood'] ?? false,
      oil: json['oil'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sugar': sugar,
      'salt': salt,
      'processedFood': processedFood,
      'oil': oil,
    };
  }
}

class Ingredient {
  final String name;
  final num quantity;
  final String unit;
  final String category;
  final String priceLevel;
  final String description;
  final bool isScalable;
  final String? image;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.priceLevel,
    required this.description,
    this.isScalable = true,
    this.image,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'g',
      category: json['category'] ?? 'Other',
      priceLevel: json['priceLevel'] ?? '₹₹',
      description: json['description'] ?? '',
      isScalable: json['isScalable'] ?? true,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'priceLevel': priceLevel,
      'description': description,
      'isScalable': isScalable,
      'image': image,
    };
  }

  Ingredient copyWith({num? quantity, String? unit}) {
    return Ingredient(
      name: name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category,
      priceLevel: priceLevel,
      description: description,
      isScalable: isScalable,
      image: image,
    );
  }
}

class ServingSize {
  final num? quantity;
  final String? unit;
  final int? servings;

  ServingSize({this.quantity, this.unit, this.servings});

  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      quantity: json['quantity'],
      unit: json['unit'],
      servings: json['servings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'quantity': quantity, 'unit': unit, 'servings': servings};
  }
}

class Nutrition {
  final num? calories;
  final num? protein;
  final num? carbs;
  final num? fats;
  final num? fiber;

  Nutrition({this.calories, this.protein, this.carbs, this.fats, this.fiber});

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fats: json['fats'],
      fiber: json['fiber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
    };
  }
}

/// Saved recipe model (after saving to database)
class SavedRecipe {
  final String id;
  final String dieticianId;
  final String name;
  final String? description;
  final String category;
  final String? cuisine;
  final String servingTime;
  final int servings;
  final int? preparationTime;
  final int? cookingTime;
  final DietaryHabits? dietaryHabits;
  final FreeFrom? freeFrom;
  final List<Ingredient>? ingredients;
  final ServingSize? servingSize;
  final Nutrition? nutrition;
  final List<String>? cookingSteps;
  final String? image;
  final String? language;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedRecipe({
    required this.id,
    required this.dieticianId,
    required this.name,
    this.description,
    required this.category,
    this.cuisine,
    required this.servingTime,
    required this.servings,
    this.preparationTime,
    this.cookingTime,
    this.dietaryHabits,
    this.freeFrom,
    this.ingredients,
    this.servingSize,
    this.nutrition,
    this.cookingSteps,
    this.image,
    this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedRecipe.fromJson(Map<String, dynamic> json) {
    return SavedRecipe(
      id: json['_id'] ?? '',
      dieticianId: json['dieticianId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'Indian',
      cuisine: json['cuisine'],
      servingTime: json['servingTime'] ?? '',
      servings: json['servings'] ?? 1,
      preparationTime: json['preparationTime'],
      cookingTime: json['cookingTime'],
      dietaryHabits: json['dietaryHabits'] != null
          ? DietaryHabits.fromJson(json['dietaryHabits'])
          : null,
      freeFrom: json['freeFrom'] != null
          ? FreeFrom.fromJson(json['freeFrom'])
          : null,
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => Ingredient.fromJson(e))
          .toList(),
      servingSize: json['servingSize'] != null
          ? ServingSize.fromJson(json['servingSize'])
          : null,
      nutrition: json['nutrition'] != null
          ? Nutrition.fromJson(json['nutrition'])
          : null,
      cookingSteps: json['cookingSteps'] != null
          ? List<String>.from(json['cookingSteps'])
          : null,
      image: json['image'],
      language: json['language'] is List
          ? (json['language'] as List).join(', ')
          : json['language'] as String?,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'dieticianId': dieticianId,
      'name': name,
      'description': description,
      'category': category,
      'cuisine': cuisine,
      'servingTime': servingTime,
      'servings': servings,
      'preparationTime': preparationTime,
      'cookingTime': cookingTime,
      'dietaryHabits': dietaryHabits?.toJson(),
      'freeFrom': freeFrom?.toJson(),
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
      'servingSize': servingSize?.toJson(),
      'nutrition': nutrition?.toJson(),
      'cookingSteps': cookingSteps,
      'image': image,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
