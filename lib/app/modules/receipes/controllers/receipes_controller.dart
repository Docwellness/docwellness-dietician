import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class DietOption {
  String name;
  bool isSelected;

  DietOption({required this.name, this.isSelected = false});
}

class CheckItemModel {
  final String title;
  final String key;
  bool isChecked;

  CheckItemModel({
    required this.title,
    required this.key,
    this.isChecked = false,
  });
}

class ReceipesController extends GetxController {
  final RecipeService _recipeService = RecipeService();

  // Form controllers
  final recipeNameController = TextEditingController();
  final customPreferencesController = TextEditingController();

  // Dropdown selections
  RxString selectedServingTime = ''.obs;
  RxString selectedServingCount = ''.obs;
  // Recipe language(s). Multiple selections allowed so AI generates content
  // in all chosen languages (e.g., Hindi + Marathi => उदाहरण in both scripts).
  RxList<String> selectedLanguages = <String>['English'].obs;

  /// Comma-joined language string sent to backend AI service.
  String get languagePayload => selectedLanguages.join(', ');

  /// Toggle a language. Ensures at least one language is always selected.
  void toggleLanguage(String lang) {
    if (selectedLanguages.contains(lang)) {
      if (selectedLanguages.length > 1) {
        selectedLanguages.remove(lang);
      }
    } else {
      selectedLanguages.add(lang);
    }
  }

  // Dietary habits options
  RxList<DietOption> dietOptions = <DietOption>[
    DietOption(name: "Vegan"),
    DietOption(name: "Jain"),
    DietOption(name: "Vegetarian"),
    DietOption(name: "Non-Vegetarian"),
    DietOption(name: "Eggetarian"),
  ].obs;

  // Free from options
  RxList<CheckItemModel> freeFromOptions = <CheckItemModel>[
    CheckItemModel(title: "Sugar", key: "sugar"),
    CheckItemModel(title: "Salt", key: "salt"),
    CheckItemModel(title: "Processed food Ingredients", key: "processedFood"),
    CheckItemModel(title: "Oil", key: "oil"),
  ].obs;

  // Loading states
  RxBool isGenerating = false.obs;
  RxBool isSaving = false.obs;
  RxBool isLoadingRecipes = false.obs;
  RxBool isLoadingCategories = false.obs;

  // Generated recipe preview
  Rx<RecipePreview?> generatedRecipe = Rx<RecipePreview?>(null);
  RxString recipeImageUrl = ''.obs;

  // Error message
  RxString errorMessage = ''.obs;

  // Recipe list data
  RxList<RecipeCategory> categories = <RecipeCategory>[].obs;
  RxList<RecipeListItem> recipes = <RecipeListItem>[].obs;
  RxString selectedCategory = 'All'.obs;
  RxInt totalRecipes = 0.obs;
  RxBool hasMoreRecipes = false.obs;
  int _currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchRecipes();
  }

  /// Fetch recipe categories
  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final result = await _recipeService.getRecipeCategories();
      categories.value = result;
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Fetch recipes with optional category filter
  Future<void> fetchRecipes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      recipes.clear();
    }

    isLoadingRecipes.value = true;
    try {
      final result = await _recipeService.listRecipes(
        category: selectedCategory.value,
        page: _currentPage,
        limit: 20,
      );

      if (refresh || _currentPage == 1) {
        recipes.value = result.recipes;
      } else {
        recipes.addAll(result.recipes);
      }

      totalRecipes.value = result.total;
      hasMoreRecipes.value = result.hasMore;
    } finally {
      isLoadingRecipes.value = false;
    }
  }

  /// Load more recipes (pagination)
  Future<void> loadMoreRecipes() async {
    if (!hasMoreRecipes.value || isLoadingRecipes.value) return;
    _currentPage++;
    await fetchRecipes();
  }

  /// Fetch single recipe by ID
  Future<RecipePreview?> fetchRecipeById(String id) async {
    try {
      final result = await _recipeService.getRecipeById(id);
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Change selected category and refresh recipes
  void changeCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    fetchRecipes(refresh: true);
  }

  // Get selected dietary options as list of strings
  List<String> get selectedOptions =>
      dietOptions.where((e) => e.isSelected).map((e) => e.name).toList();

  // Build DietaryHabits object from selections
  DietaryHabits get dietaryHabits {
    return DietaryHabits(
      vegan: dietOptions.any((e) => e.name == "Vegan" && e.isSelected),
      jain: dietOptions.any((e) => e.name == "Jain" && e.isSelected),
      vegetarian: dietOptions.any(
        (e) => e.name == "Vegetarian" && e.isSelected,
      ),
      nonVegetarian: dietOptions.any(
        (e) => e.name == "Non-Vegetarian" && e.isSelected,
      ),
      eggitarian: dietOptions.any(
        (e) => e.name == "Eggetarian" && e.isSelected,
      ),
    );
  }

  // Build FreeFrom object from selections
  FreeFrom get freeFrom {
    return FreeFrom(
      sugar: freeFromOptions.any((e) => e.key == "sugar" && e.isChecked),
      salt: freeFromOptions.any((e) => e.key == "salt" && e.isChecked),
      processedFood: freeFromOptions.any(
        (e) => e.key == "processedFood" && e.isChecked,
      ),
      oil: freeFromOptions.any((e) => e.key == "oil" && e.isChecked),
    );
  }

  // Validate form inputs
  String? validateInputs() {
    if (recipeNameController.text.trim().isEmpty) {
      return 'Please enter a recipe name';
    }
    if (selectedServingTime.value.isEmpty) {
      return 'Please select a serving time';
    }
    if (selectedServingCount.value.isEmpty) {
      return 'Please select number of servings';
    }
    return null;
  }

  /// Generate recipe preview using AI
  Future<RecipePreview?> generateRecipePreview() async {
    // Validate inputs
    final validationError = validateInputs();
    if (validationError != null) {
      errorMessage.value = validationError;
      Get.snackbar('Validation Error', validationError);
      return null;
    }

    isGenerating.value = true;
    errorMessage.value = '';

    try {
      final servings = int.tryParse(selectedServingCount.value) ?? 1;

      final result = await _recipeService.generateRecipePreview(
        name: recipeNameController.text.trim(),
        servingTime: selectedServingTime.value,
        servings: servings,
        dietaryHabits: dietaryHabits,
        freeFrom: freeFrom,
        aiNote: customPreferencesController.text.trim().isNotEmpty
            ? customPreferencesController.text.trim()
            : null,
        language: languagePayload,
      );

      if (result != null) {
        generatedRecipe.value = result;
        debugPrint('✅ Recipe generated successfully: ${result.name}');
        return result;
      } else {
        errorMessage.value = 'Failed to generate recipe. Please try again.';
        Get.snackbar('Error', errorMessage.value);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error generating recipe: $e');
      errorMessage.value = 'An error occurred. Please try again.';
      Get.snackbar('Error', errorMessage.value);
      return null;
    } finally {
      isGenerating.value = false;
    }
  }

  /// Save the generated recipe to database
  Future<SavedRecipe?> saveRecipe() async {
    if (generatedRecipe.value == null) {
      debugPrint('❌ No recipe to save - generatedRecipe.value is null');
      return null;
    }

    isSaving.value = true;

    try {
      final recipe = generatedRecipe.value!;
      debugPrint('💾 Attempting to save recipe: ${recipe.name}');

      final result = await _recipeService.createRecipe(
        name: recipe.name,
        servingTime: recipe.servingTime,
        servings: recipe.servings,
        category: recipe.category,
        description: recipe.description,
        dietaryHabits: recipe.dietaryHabits,
        freeFrom: recipe.freeFrom,
        servingSize: recipe.servingSize,
        ingredients: recipe.ingredients,
        cookingSteps: recipe.cookingSteps,
        nutrition: recipe.nutrition,
        image: recipeImageUrl.value.isNotEmpty ? recipeImageUrl.value : null,
        language: languagePayload,
        translations: recipe.translations.isNotEmpty
            ? recipe.translations
            : null,
      );

      if (result != null) {
        debugPrint('✅ Recipe saved successfully: ${result.id}');
        clearForm();
        return result;
      } else {
        debugPrint('❌ Recipe save failed - API returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error saving recipe: $e');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  /// Clear the form
  /// Update recipe using AI with current edits
  /// Sends current inputs + existing ingredients/instructions/nutrition
  /// so AI refines rather than regenerating from scratch
  RxBool isUpdatingAi = false.obs;

  Future<RecipePreview?> updateAiInputs() async {
    if (generatedRecipe.value == null) {
      Get.snackbar('Error', 'No recipe to update');
      return null;
    }

    final validationError = validateInputs();
    if (validationError != null) {
      errorMessage.value = validationError;
      Get.snackbar('Validation Error', validationError);
      return null;
    }

    isUpdatingAi.value = true;
    errorMessage.value = '';

    try {
      final servings = int.tryParse(selectedServingCount.value) ?? 1;
      final currentRecipe = generatedRecipe.value!;

      final result = await _recipeService.updateRecipeFromEdits(
        name: recipeNameController.text.trim(),
        servingTime: selectedServingTime.value,
        servings: servings,
        dietaryHabits: dietaryHabits,
        freeFrom: freeFrom,
        aiNote: customPreferencesController.text.trim().isNotEmpty
            ? customPreferencesController.text.trim()
            : null,
        ingredients: currentRecipe.ingredients,
        instructions: currentRecipe.cookingSteps,
        nutrition: currentRecipe.nutrition,
        language: languagePayload,
      );

      if (result != null) {
        generatedRecipe.value = result;
        debugPrint('✅ Recipe updated via AI: ${result.name}');
        return result;
      } else {
        errorMessage.value = 'Failed to update recipe. Please try again.';
        Get.snackbar('Error', errorMessage.value);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error updating recipe: $e');
      errorMessage.value = 'An error occurred. Please try again.';
      Get.snackbar('Error', errorMessage.value);
      return null;
    } finally {
      isUpdatingAi.value = false;
    }
  }

  /// Pre-fill form fields from existing recipe (for Update AI Inputs)
  void prefillFromRecipe(RecipePreview recipe) {
    recipeNameController.text = recipe.name;
    selectedServingTime.value = recipe.servingTime;
    selectedServingCount.value = recipe.servings.toString();
    // Only overwrite with the recipe's image when it actually has one,
    // otherwise keep the URL the user just uploaded in this session.
    if (recipe.image != null && recipe.image!.isNotEmpty) {
      recipeImageUrl.value = recipe.image!;
    }
    selectedLanguages.value = recipe.languages.isNotEmpty
        ? List<String>.from(recipe.languages)
        : ['English'];

    // Set dietary habits
    for (var option in dietOptions) {
      switch (option.name) {
        case 'Vegan':
          option.isSelected = recipe.dietaryHabits.vegan;
          break;
        case 'Jain':
          option.isSelected = recipe.dietaryHabits.jain;
          break;
        case 'Vegetarian':
          option.isSelected = recipe.dietaryHabits.vegetarian;
          break;
        case 'Non-Vegetarian':
          option.isSelected = recipe.dietaryHabits.nonVegetarian;
          break;
        case 'Eggetarian':
          option.isSelected = recipe.dietaryHabits.eggitarian;
          break;
      }
    }
    dietOptions.refresh();

    // Set free from
    for (var option in freeFromOptions) {
      switch (option.key) {
        case 'sugar':
          option.isChecked = recipe.freeFrom.sugar;
          break;
        case 'salt':
          option.isChecked = recipe.freeFrom.salt;
          break;
        case 'processedFood':
          option.isChecked = recipe.freeFrom.processedFood;
          break;
        case 'oil':
          option.isChecked = recipe.freeFrom.oil;
          break;
      }
    }
    freeFromOptions.refresh();
  }

  void clearForm() {
    recipeNameController.clear();
    customPreferencesController.clear();
    selectedServingTime.value = '';
    selectedServingCount.value = '';
    for (var option in dietOptions) {
      option.isSelected = false;
    }
    dietOptions.refresh();
    for (var option in freeFromOptions) {
      option.isChecked = false;
    }
    freeFromOptions.refresh();
    generatedRecipe.value = null;
    recipeImageUrl.value = '';
    selectedLanguages.value = ['English'];
    errorMessage.value = '';
  }

  @override
  void onClose() {
    recipeNameController.dispose();
    customPreferencesController.dispose();
    super.onClose();
  }
}
