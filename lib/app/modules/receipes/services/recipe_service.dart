import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

/// Thrown when the backend rejects a recipe request with a specific,
/// user-facing reason (e.g. a dietary constraint conflict) rather than a
/// generic failure, so the UI can show the real cause instead of a fallback
/// "something went wrong" message.
class RecipeApiException implements Exception {
  final String message;
  final List<String> errors;

  RecipeApiException(this.message, {this.errors = const []});

  /// Human-readable text combining the top-level message with any detailed
  /// per-conflict errors, suitable for showing directly in a snackbar.
  String get displayMessage =>
      errors.isEmpty ? message : errors.join('\n');
}

class RecipeService {
  final ApiService _apiService = ApiService();

  /// Generate a recipe preview using AI
  /// POST /api/dietician/recipes/ai-generate-preview
  Future<RecipePreview?> generateRecipePreview({
    required String name,
    required String servingTime,
    required int servings,
    DietaryHabits? dietaryHabits,
    FreeFrom? freeFrom,
    String? aiNote,
    String? language,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'servingTime': servingTime,
        'servings': servings,
        if (dietaryHabits != null) 'dietaryHabits': dietaryHabits.toJson(),
        if (freeFrom != null) 'freeFrom': freeFrom.toJson(),
        if (aiNote != null && aiNote.isNotEmpty) 'aiNote': aiNote,
        if (language != null) 'language': language,
      };

      final response = await _apiService.request(
        endPoint: '/recipes/ai-generate-preview',
        method: 'POST',
        data: requestBody,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return RecipePreview.fromJson(response.data['data']);
      }

      print(
        '❌ generateRecipePreview failed: status=${response?.statusCode}, data=${response?.data}',
      );

      if (response?.data is Map && response!.data['message'] != null) {
        final rawErrors = response.data['errors'];
        throw RecipeApiException(
          response.data['message'] as String,
          errors: rawErrors is List ? rawErrors.map((e) => e.toString()).toList() : const [],
        );
      }
      return null;
    } catch (e) {
      if (e is RecipeApiException) rethrow;
      print('❌ generateRecipePreview exception: $e');
      return null;
    }
  }

  /// Update recipe preview based on dietician edits
  /// POST /api/dietician/recipes/ai-update-from-edits
  Future<RecipePreview?> updateRecipeFromEdits({
    required String name,
    required String servingTime,
    required int servings,
    required List<Ingredient> ingredients,
    DietaryHabits? dietaryHabits,
    FreeFrom? freeFrom,
    String? aiNote,
    List<String>? instructions,
    Nutrition? nutrition,
    String? language,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'servingTime': servingTime,
        'servings': servings,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        if (dietaryHabits != null) 'dietaryHabits': dietaryHabits.toJson(),
        if (freeFrom != null) 'freeFrom': freeFrom.toJson(),
        if (aiNote != null && aiNote.isNotEmpty) 'aiNote': aiNote,
        if (instructions != null) 'instructions': instructions,
        if (nutrition != null) 'nutrition': nutrition.toJson(),
        if (language != null) 'language': language,
      };

      final response = await _apiService.request(
        endPoint: '/recipes/ai-update-from-edits',
        method: 'POST',
        data: requestBody,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return RecipePreview.fromJson(response.data['data']);
      }

      if (response?.data is Map && response!.data['message'] != null) {
        final rawErrors = response.data['errors'];
        throw RecipeApiException(
          response.data['message'] as String,
          errors: rawErrors is List ? rawErrors.map((e) => e.toString()).toList() : const [],
        );
      }
      return null;
    } catch (e) {
      if (e is RecipeApiException) rethrow;
      return null;
    }
  }

  /// Create/save a recipe to the database
  /// POST /api/dietician/recipes
  Future<SavedRecipe?> createRecipe({
    required String name,
    required String servingTime,
    required int servings,
    String? category,
    String? description,
    DietaryHabits? dietaryHabits,
    FreeFrom? freeFrom,
    ServingSize? servingSize,
    List<Ingredient>? ingredients,
    List<String>? cookingSteps,
    Nutrition? nutrition,
    String? image,
    String? language,
    Map<String, RecipeTranslation>? translations,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'servingTime': servingTime,
        'servings': servings,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (dietaryHabits != null) 'dietaryHabits': dietaryHabits.toJson(),
        if (freeFrom != null) 'freeFrom': freeFrom.toJson(),
        if (servingSize != null) 'servingSize': servingSize.toJson(),
        if (ingredients != null)
          'ingredients': ingredients.map((e) => e.toJson()).toList(),
        if (cookingSteps != null) 'cookingSteps': cookingSteps,
        if (nutrition != null) 'nutrition': nutrition.toJson(),
        if (image != null) 'image': image,
        if (language != null) 'language': language,
        if (translations != null && translations.isNotEmpty)
          'translations': translations.map(
            (key, value) => MapEntry(key, value.toJson()),
          ),
      };

      final response = await _apiService.request(
        endPoint: '/recipes',
        method: 'POST',
        data: requestBody,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 201 &&
          response.data['success'] == true) {
        // Guard against future schema drift: if fromJson throws, the recipe
        // is still persisted on the server. Return a minimal SavedRecipe so
        // the UI doesn't prompt the user to retry (which would duplicate it).
        try {
          return SavedRecipe.fromJson(response.data['data']);
        } catch (parseErr) {
          print('⚠️ createRecipe parse failed but save succeeded: $parseErr');
          final data = response.data['data'] ?? {};
          return SavedRecipe(
            id: (data['_id'] ?? '').toString(),
            dieticianId: (data['dieticianId'] ?? '').toString(),
            name: data['name']?.toString() ?? name,
            category: data['category']?.toString() ?? 'Indian',
            servingTime: data['servingTime']?.toString() ?? servingTime,
            servings: data['servings'] is int
                ? data['servings'] as int
                : servings,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }

      print(
        '❌ createRecipe failed: status=${response?.statusCode}, data=${response?.data}',
      );
      return null;
    } catch (e) {
      print('❌ createRecipe exception: $e');
      return null;
    }
  }

  /// List recipes by serving time
  /// GET /api/dietician/recipes/by-serving-time
  Future<List<Map<String, dynamic>>> listRecipesByServingTime({
    required String servingTime,
    String? cuisine,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // servingTime values like "Night Drink"/"Morning Drink"/"Evening
      // Snack" contain a space - building the query string by raw
      // interpolation (as this used to) sent an unencoded space in the
      // URL, which the backend couldn't match against VALID_SERVING_TIMES,
      // so every space-containing serving time silently came back empty
      // (this method's own catch-all returns [] on any non-200/exception,
      // which is exactly what rendered as "No recipes found"). Passing a
      // queryParameters map instead lets Dio URL-encode each value
      // correctly.
      final response = await _apiService.request(
        endPoint: '/recipes/by-serving-time',
        method: 'GET',
        queryParameters: {
          'servingTime': servingTime,
          'page': page,
          'limit': limit,
          if (cuisine != null) 'cuisine': cuisine,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get recipe categories with counts
  /// GET /api/dietician/recipes/categories
  Future<List<RecipeCategory>> getRecipeCategories() async {
    try {
      final response = await _apiService.request(
        endPoint: '/recipes/categories',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => RecipeCategory.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Real recipe counts per serving-time slot, optionally scoped to a
  /// top-level category group, plus the Supplements total - powers the
  /// "Recipes & Supplements" landing grid.
  /// GET /api/dietician/recipes/serving-time-summary
  Future<ServingTimeSummary> getServingTimeSummary({String? topCategory}) async {
    try {
      final query = (topCategory != null && topCategory != 'All')
          ? '?topCategory=$topCategory'
          : '';
      final response = await _apiService.request(
        endPoint: '/recipes/serving-time-summary$query',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return ServingTimeSummary.fromJson(response.data['data']);
      }
      return ServingTimeSummary(counts: [], supplementsCount: 0);
    } catch (e) {
      return ServingTimeSummary(counts: [], supplementsCount: 0);
    }
  }

  /// List all recipes with optional category/topCategory/servingTime filters
  /// GET /api/dietician/recipes
  Future<RecipeListResponse> listRecipes({
    String? category,
    String? topCategory,
    String? servingTime,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // See listRecipesByServingTime above - values like "Night Drink" or
      // "Healthy Bowls" contain spaces, so building this as a raw string
      // (as this used to) sent unencoded query params and silently
      // returned empty results for any such category/servingTime.
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null && category != 'All') 'category': category,
        if (topCategory != null && topCategory != 'All')
          'topCategory': topCategory,
        if (servingTime != null && servingTime.isNotEmpty)
          'servingTime': servingTime,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      };

      final response = await _apiService.request(
        endPoint: '/recipes',
        method: 'GET',
        queryParameters: queryParameters,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return RecipeListResponse.fromJson(response.data);
      }

      return RecipeListResponse(recipes: [], pagination: null);
    } catch (e) {
      return RecipeListResponse(recipes: [], pagination: null);
    }
  }

  /// Get single recipe by ID
  /// GET /api/dietician/recipes/:id
  Future<RecipePreview?> getRecipeById(String id) async {
    try {
      final response = await _apiService.request(
        endPoint: '/recipes/$id',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final data = response.data['data'];
        return RecipePreview.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Patch an existing recipe (currently supports image)
  /// PATCH /api/dietician/recipes/:id
  Future<bool> updateRecipeFields({required String id, String? image}) async {
    try {
      final body = <String, dynamic>{};
      if (image != null) body['image'] = image;
      if (body.isEmpty) return false;

      final response = await _apiService.request(
        endPoint: '/recipes/$id',
        method: 'PATCH',
        data: body,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      print('❌ updateRecipeFields exception: $e');
      return false;
    }
  }

  /// Persist the full edited state of an already-saved recipe - used by the
  /// "Save Recipe" button on an existing recipe's detail screen, since
  /// "Update AI Inputs" only refines the in-memory preview and never writes
  /// to the database on its own. Includes any ingredient image refreshes.
  /// PATCH /api/dietician/recipes/:id
  Future<bool> saveExistingRecipe({
    required String id,
    required String servingTime,
    required int servings,
    String? category,
    String? description,
    DietaryHabits? dietaryHabits,
    FreeFrom? freeFrom,
    List<Ingredient>? ingredients,
    List<String>? cookingSteps,
    Nutrition? nutrition,
    Map<String, RecipeTranslation>? translations,
  }) async {
    try {
      final body = <String, dynamic>{
        'servingTime': servingTime,
        'servings': servings,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (dietaryHabits != null) 'dietaryHabits': dietaryHabits.toJson(),
        if (freeFrom != null) 'freeFrom': freeFrom.toJson(),
        if (ingredients != null)
          'ingredients': ingredients.map((e) => e.toJson()).toList(),
        if (cookingSteps != null) 'cookingSteps': cookingSteps,
        if (nutrition != null) 'nutrition': nutrition.toJson(),
        if (translations != null && translations.isNotEmpty)
          'translations': translations.map(
            (key, value) => MapEntry(key, value.toJson()),
          ),
      };

      final response = await _apiService.request(
        endPoint: '/recipes/$id',
        method: 'PATCH',
        data: body,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      print('❌ saveExistingRecipe exception: $e');
      return false;
    }
  }

  /// Upload main recipe image to Cloudinary via backend
  /// POST /api/dietician/uploads/recipe-image
  Future<String?> uploadRecipeImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.request(
        endPoint: '/uploads/recipe-image',
        method: 'POST',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']?['url']?.toString();
      }

      print(
        '❌ uploadRecipeImage failed: status=${response?.statusCode}, data=${response?.data}',
      );
      return null;
    } catch (e) {
      print('❌ uploadRecipeImage exception: $e');
      return null;
    }
  }

  /// Upload ingredient image to Cloudinary via backend
  /// POST /api/dietician/uploads/ingredient-image
  Future<String?> uploadIngredientImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiService.request(
        endPoint: '/uploads/ingredient-image',
        method: 'POST',
        data: formData,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']?['url']?.toString();
      }

      print(
        '❌ uploadIngredientImage failed: status=${response?.statusCode}, data=${response?.data}',
      );
      return null;
    } catch (e) {
      print('❌ uploadIngredientImage exception: $e');
      return null;
    }
  }

  /// Fetch a real photo of an ingredient from the internet (Pexels, mirrored
  /// into Cloudinary server-side) - replaces the device-upload flow. Can be
  /// called repeatedly for the same ingredient to get a different result.
  /// POST /api/dietician/uploads/ingredient-image/fetch
  Future<String?> fetchIngredientImageFromWeb(String ingredientName) async {
    try {
      final response = await _apiService.request(
        endPoint: '/uploads/ingredient-image/fetch',
        method: 'POST',
        data: {'ingredientName': ingredientName},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']?['url']?.toString();
      }

      print(
        '❌ fetchIngredientImageFromWeb failed: status=${response?.statusCode}, data=${response?.data}',
      );
      return null;
    } catch (e) {
      print('❌ fetchIngredientImageFromWeb exception: $e');
      return null;
    }
  }

  /// Persist a single ingredient's refreshed image on an already-saved
  /// recipe (only relevant when editing an existing recipe, not a
  /// not-yet-saved preview - see recipe_details.dart's fromAddRecipeScreen).
  /// Matches by array index, not name - a recipe can have two ingredients
  /// with the same name, and the backend only updates the exact index sent.
  /// PATCH /api/dietician/recipes/:id/ingredient-image
  Future<bool> updateIngredientImage({
    required String recipeId,
    required int ingredientIndex,
    required String imageUrl,
  }) async {
    try {
      final response = await _apiService.request(
        endPoint: '/recipes/$recipeId/ingredient-image',
        method: 'PATCH',
        data: {'ingredientIndex': ingredientIndex, 'imageUrl': imageUrl},
        headers: {'Authorization': 'Bearer $token'},
      );

      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      print('❌ updateIngredientImage exception: $e');
      return false;
    }
  }
}

/// Recipe Category model
class RecipeCategory {
  final String name;
  final int count;
  final String? image;

  RecipeCategory({required this.name, required this.count, this.image});

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      name: json['name'] ?? 'Other',
      count: json['count'] ?? 0,
      image: json['image'],
    );
  }
}

/// Real per-serving-time recipe count, e.g. {servingTime: 'Breakfast', count: 19}.
class ServingTimeCount {
  final String servingTime;
  final int count;

  ServingTimeCount({required this.servingTime, required this.count});

  factory ServingTimeCount.fromJson(Map<String, dynamic> json) {
    return ServingTimeCount(
      servingTime: json['servingTime'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

/// Response shape for GET /recipes/serving-time-summary - the 7 real
/// serving-time counts plus the always-present Supplements shortcut count.
class ServingTimeSummary {
  final List<ServingTimeCount> counts;
  final int supplementsCount;
  final int sidesCount;
  final int saladCount;

  ServingTimeSummary({
    required this.counts,
    required this.supplementsCount,
    this.sidesCount = 0,
    this.saladCount = 0,
  });

  factory ServingTimeSummary.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['servingTimeCounts'] as List? ?? [];
    return ServingTimeSummary(
      counts: rawCounts.map((e) => ServingTimeCount.fromJson(e)).toList(),
      supplementsCount: json['supplementsCount'] ?? 0,
      sidesCount: json['sidesCount'] ?? 0,
      saladCount: json['saladCount'] ?? 0,
    );
  }

  int countFor(String servingTime) =>
      counts.firstWhere(
        (c) => c.servingTime == servingTime,
        orElse: () => ServingTimeCount(servingTime: servingTime, count: 0),
      ).count;
}

/// Recipe list item model
class RecipeListItem {
  final String id;
  final String name;
  final String? image;
  final String category;
  final String cuisine;
  final String servingTime;
  final int servings;
  final int ingredientsCount;
  final int? calories;
  final String description;
  final DateTime? createdAt;

  RecipeListItem({
    required this.id,
    required this.name,
    this.image,
    required this.category,
    required this.cuisine,
    required this.servingTime,
    required this.servings,
    required this.ingredientsCount,
    this.calories,
    required this.description,
    this.createdAt,
  });

  factory RecipeListItem.fromJson(Map<String, dynamic> json) {
    return RecipeListItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      category: json['category'] ?? 'Other',
      cuisine: json['cuisine'] ?? '',
      servingTime: json['servingTime'] ?? '',
      servings: json['servings'] ?? 1,
      ingredientsCount: json['ingredientsCount'] ?? 0,
      // nutrition.calories is stored as a Mongoose Number and can come back
      // as a double (e.g. 8.6) - assigning that directly to this int? field
      // throws a runtime TypeError ("double is not a subtype of int"),
      // which the caller's try/catch swallowed into an empty recipe list.
      calories: (json['calories'] as num?)?.round(),
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

/// Recipe list response with pagination
class RecipeListResponse {
  final List<RecipeListItem> recipes;
  final Map<String, dynamic>? pagination;

  RecipeListResponse({required this.recipes, this.pagination});

  factory RecipeListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return RecipeListResponse(
      recipes: data.map((e) => RecipeListItem.fromJson(e)).toList(),
      pagination: json['pagination'],
    );
  }

  int get total => pagination?['total'] ?? recipes.length;
  bool get hasMore => pagination?['hasMore'] ?? false;
}
