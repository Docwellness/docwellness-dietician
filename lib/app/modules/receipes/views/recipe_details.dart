import 'package:docwellnesdoc/app/modules/home/controllers/home_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/cooking_steps_tab.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/ingredient_tile.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/nutrition_details_widget.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/update_ai_inputs_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final ScrollController scrollController;
  final bool fromAddRecipeScreen;
  final RecipePreview? recipePreview;

  const RecipeDetailsScreen({
    super.key,
    required this.scrollController,
    required this.fromAddRecipeScreen,
    this.recipePreview,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  int selectedTab = 0;
  int counter = 1;
  String _selectedLanguage = 'English';
  final ImagePicker _imagePicker = ImagePicker();
  final RecipeService _recipeService = RecipeService();
  final Set<int> _uploadingIngredientIndexes = <int>{};
  RecipePreview? _editableRecipe;
  bool _isUploadingMainImage = false;
  bool _isSavingExistingRecipe = false;
  String? _mainImageUrl;

  RecipePreview? get recipe {
    if (_editableRecipe != null) return _editableRecipe;

    if (widget.fromAddRecipeScreen) {
      // Use the controller's reactive recipe (updated by Update AI Inputs)
      final controller = Get.find<ReceipesController>();
      return controller.generatedRecipe.value ?? widget.recipePreview;
    }
    return widget.recipePreview;
  }

  String get recipeName {
    if (_selectedLanguage != 'English' && recipe != null) {
      final t = recipe!.translations[_selectedLanguage];
      if (t != null && t.name.isNotEmpty) return t.name;
    }
    return recipe?.name ?? 'Recipe name';
  }

  String get recipeCategory => recipe?.category ?? '';

  String get recipeDescription {
    if (recipe != null) {
      final calories = recipe!.nutrition.calories ?? 0;
      final cuisine = recipe!.cuisine;
      return '$cuisine • $calories calories';
    }
    return 'Vitamin rich • 450 calories';
  }

  List<String> get warnings {
    if (_selectedLanguage != 'English' && recipe != null) {
      final t = recipe!.translations[_selectedLanguage];
      if (t != null && t.warnings.isNotEmpty) return t.warnings;
    }
    return recipe?.warnings ?? [];
  }

  List<Ingredient> get ingredients => recipe?.ingredients ?? [];

  /// Get ingredient name for display (translated if available)
  String ingredientName(int index) {
    if (_selectedLanguage != 'English' && recipe != null) {
      final t = recipe!.translations[_selectedLanguage];
      if (t != null && index < t.ingredients.length) {
        final translated = t.ingredients[index].name;
        if (translated.isNotEmpty) return translated;
      }
    }
    return ingredients[index].name;
  }

  /// Get ingredient description for display (translated if available)
  String ingredientDescription(int index) {
    if (_selectedLanguage != 'English' && recipe != null) {
      final t = recipe!.translations[_selectedLanguage];
      if (t != null && index < t.ingredients.length) {
        final translated = t.ingredients[index].description;
        if (translated.isNotEmpty) return translated;
      }
    }
    return ingredients[index].description;
  }

  List<String> get cookingSteps {
    if (_selectedLanguage != 'English' && recipe != null) {
      final t = recipe!.translations[_selectedLanguage];
      if (t != null && t.cookingSteps.isNotEmpty) return t.cookingSteps;
    }
    return recipe?.cookingSteps ?? [];
  }

  Nutrition get nutrition => recipe?.nutrition ?? Nutrition();

  List<String> get availableLanguages {
    final langs = recipe?.languages ?? ['English'];
    if (!langs.contains('English')) return ['English', ...langs];
    return langs;
  }

  @override
  void initState() {
    super.initState();
    counter = recipe?.servings ?? 1;
    // Auto-select the user's chosen language instead of defaulting to English
    final langs = recipe?.languages ?? ['English'];
    if (langs.isNotEmpty && langs.any((l) => l != 'English')) {
      _selectedLanguage = langs.firstWhere((l) => l != 'English');
    }
    if (widget.fromAddRecipeScreen) {
      final controller = Get.find<ReceipesController>();
      _mainImageUrl = controller.recipeImageUrl.value.isNotEmpty
          ? controller.recipeImageUrl.value
          : recipe?.image;
    } else {
      _mainImageUrl = recipe?.image;
    }
  }

  Future<void> _pickAndUploadMainImage() async {
    if (_isUploadingMainImage) return;

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() {
      _isUploadingMainImage = true;
    });

    try {
      final imageUrl = await _recipeService.uploadRecipeImage(file.path);
      if (imageUrl == null || imageUrl.isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to upload recipe image. Please try again.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      if (widget.fromAddRecipeScreen) {
        final controller = Get.find<ReceipesController>();
        controller.recipeImageUrl.value = imageUrl;
      } else {
        // Persist the banner on the existing recipe in the DB so it shows
        // up in the list after refresh.
        final recipeId = recipe?.id;
        if (recipeId != null && recipeId.isNotEmpty) {
          final ok = await _recipeService.updateRecipeFields(
            id: recipeId,
            image: imageUrl,
          );
          if (!ok) {
            Get.snackbar(
              'Error',
              'Uploaded image but failed to save it on the recipe.',
              snackPosition: SnackPosition.TOP,
            );
          } else {
            // Refresh the list so the grid picks up the new image.
            if (Get.isRegistered<ReceipesController>()) {
              Get.find<ReceipesController>().fetchRecipes(refresh: true);
            }
          }
        }
      }

      _mainImageUrl = imageUrl;
      setState(() {});

      Get.snackbar(
        'Success',
        'Recipe image uploaded successfully.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMainImage = false;
        });
      }
    }
  }

  /// Fetches a fresh internet photo for the ingredient at [index] (Pexels,
  /// mirrored into Cloudinary server-side) - can be tapped repeatedly to get
  /// a different result. If this recipe is already saved (has an id, i.e.
  /// not the not-yet-saved preview flow), the new image is also persisted
  /// immediately; otherwise it's held in local preview state and gets
  /// written to the DB naturally when "Add to Database" is tapped.
  Future<void> _refetchIngredientImage(int index) async {
    if (recipe == null || _uploadingIngredientIndexes.contains(index)) {
      return;
    }

    final current = recipe!.ingredients[index];

    setState(() {
      _uploadingIngredientIndexes.add(index);
    });

    try {
      final imageUrl = await _recipeService.fetchIngredientImageFromWeb(
        current.name,
      );
      if (imageUrl == null || imageUrl.isEmpty || recipe == null) {
        Get.snackbar(
          'Error',
          "Couldn't find an image for this ingredient. Please try again.",
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final recipeId = recipe!.id;
      if (recipeId != null && recipeId.isNotEmpty) {
        final persisted = await _recipeService.updateIngredientImage(
          recipeId: recipeId,
          ingredientIndex: index,
          imageUrl: imageUrl,
        );
        if (!persisted) {
          Get.snackbar(
            'Error',
            'Failed to save the new image. Please try again.',
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }

      final updatedIngredients = List<Ingredient>.from(recipe!.ingredients);

      updatedIngredients[index] = Ingredient(
        name: current.name,
        quantity: current.quantity,
        unit: current.unit,
        category: current.category,
        priceLevel: current.priceLevel,
        description: current.description,
        isScalable: current.isScalable,
        image: imageUrl,
      );

      final updatedRecipeMap = recipe!.toJson();
      updatedRecipeMap['ingredients'] = updatedIngredients
          .map((e) => e.toJson())
          .toList();

      final updatedRecipe = RecipePreview.fromJson(updatedRecipeMap);
      final controller = Get.find<ReceipesController>();
      controller.generatedRecipe.value = updatedRecipe;
      _editableRecipe = updatedRecipe;

      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _uploadingIngredientIndexes.remove(index);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // top placeholder image
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10, top: 10),
            decoration: BoxDecoration(
              color: Color(0xff79747E),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Stack(
          children: [
            Container(
              height: 196,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                border: Border.all(color: const Color(0xffE5E7EB)),
              ),
              child: (_mainImageUrl != null && _mainImageUrl!.trim().isNotEmpty)
                  ? Image.network(_mainImageUrl!, fit: BoxFit.cover)
                  : Center(
                      child: _isUploadingMainImage
                          ? const SizedBox(
                              height: 34,
                              width: 34,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                              ),
                            )
                          : const Icon(
                              Icons.add,
                              size: 72,
                              color: Color(0xff98A2B3),
                            ),
                    ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploadingMainImage ? null : _pickAndUploadMainImage,
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: InkWell(
                onTap: _isUploadingMainImage ? null : _pickAndUploadMainImage,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xff530630),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isUploadingMainImage
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),

        Padding(
          padding: EdgeInsets.only(left: 16, top: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: recipeName,

                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff384250),
                    ),

                    CustomText(
                      text: recipeDescription,

                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff6C737F),
                    ),
                  ],
                ),
              ),
              if (recipeCategory.isNotEmpty) ...[
                SizedBox(width: 5),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDF2FA),
                    border: Border.all(color: Color(0xffFCE7F6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomText(
                      text: recipeCategory,
                      color: Color(0xFFEF45B2),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ------------------- LANGUAGE SELECTOR -------------------
        if (availableLanguages.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: availableLanguages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff530630)
                            : const Color(0xffFDF2FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff530630)
                              : const Color(0xffFCE7F6),
                        ),
                      ),
                      child: CustomText(
                        text: lang,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xff530630),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ------------------- CUSTOM SEGMENTED TAB BAR -------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Color(0xff530630), width: 1),
            ),
            child: Row(
              children: [
                _buildTab(0, "Ingredients"),
                _verticalDivider(),
                _buildTab(1, "Nutrition value"),
                _verticalDivider(),
                _buildTab(2, "Cooking steps"),
              ],
            ),
          ),
        ),

        SizedBox(height: selectedTab == 0 ? 9 : 16),

        Expanded(
          child: IndexedStack(
            index: selectedTab,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    if (selectedTab == 0 && warnings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Container(
                          padding: EdgeInsets.only(
                            right: 27,
                            left: 24,
                            top: 21,
                            bottom: 21,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xffFEF6FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/ion_warning-outline.png',
                                height: 30,
                                width: 30,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  text: warnings.join(' '),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Color(0xff851653),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (selectedTab == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              text: 'Servings',
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                              color: Color(0xff384250),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (counter > 1) {
                                        counter--;
                                      }
                                    });
                                  },

                                  child: Image.asset(
                                    'assets/icons/_x37_7_Essential_Icons.png',
                                    height: 22,
                                    width: 22,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 15),
                                CustomText(
                                  text: counter.toString(),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Color(0xffC11576),
                                ),
                                SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      counter++;
                                    });
                                  },
                                  child: Image.asset(
                                    'assets/icons/Plus.png',
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(thickness: 0.7, color: Color(0xffFCCEEF)),
                    ),
                    if (ingredients.isNotEmpty)
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = ingredients[index];
                          return IngredientTile(
                            ingredient: ingredient,
                            servingsMultiplier:
                                counter / (recipe?.servings ?? 1),
                            onRefreshImageTap: () =>
                                _refetchIngredientImage(index),
                            isUploading: _uploadingIngredientIndexes.contains(
                              index,
                            ),
                            translatedName: _selectedLanguage != 'English'
                                ? ingredientName(index)
                                : null,
                            translatedDescription:
                                _selectedLanguage != 'English'
                                ? ingredientDescription(index)
                                : null,
                          );
                        },
                      )
                    else
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return const IngredientTile();
                        },
                      ),
                  ],
                ),
              ),
              NutritionDetailsWidget(nutrition: nutrition),
              CookingStepsTab(cookingSteps: cookingSteps),
            ],
          ),
        ),
        SizedBox(height: 4),
        if (widget.fromAddRecipeScreen == true)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomButton(
              fontSize: 13.5,
              onTap: () {
                final controller = Get.find<ReceipesController>();
                // Pre-fill the form with current recipe values
                if (recipe != null) {
                  controller.prefillFromRecipe(recipe!);
                }
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  useSafeArea: true,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) {
                    return DraggableScrollableSheet(
                      initialChildSize: 1,
                      maxChildSize: 1,
                      minChildSize: 0.5,
                      expand: false,
                      builder: (ctx, scrollCtrl) {
                        return UpdateAiInputsSheet(
                          scrollController: scrollCtrl,
                          onUpdated: () {
                            // Rebuild this screen with the updated recipe
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                );
              },
              text: 'Update AI Inputs',
              isOutline: true,
            ),
          ),
        if (widget.fromAddRecipeScreen == true)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final controller = Get.find<ReceipesController>();
              return CustomButton(
                fontSize: 13.5,
                onTap: () async {
                  if (controller.isSaving.value) return;
                  final result = await controller.saveRecipe();

                  if (result != null) {
                    // Close the modal bottom sheet first
                    Navigator.of(context).pop();

                    // Go back to Recipes & Supplements screen
                    Get.until((route) => route.isFirst);

                    // Set bottom nav to Recipes tab (index 2)
                    final homeController = Get.find<HomeController>();
                    homeController.selectedIndex.value = 2;

                    // Refresh recipes list
                    controller.fetchRecipes(refresh: true);

                    // Show success message
                    Get.snackbar(
                      'Success',
                      'Recipe "${result.name}" saved successfully!',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade100,
                      colorText: Colors.green.shade900,
                      duration: const Duration(seconds: 3),
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to save recipe. Please try again.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade900,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
                text: controller.isSaving.value
                    ? 'Saving...'
                    : 'Add to Database',
                isOutline: false,
                isLoading: controller.isSaving.value,
              );
            }),
          ),
        if (widget.fromAddRecipeScreen == false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomButton(
              fontSize: 13.5,
              onTap: () {
                final controller = Get.find<ReceipesController>();
                if (recipe != null) {
                  controller.generatedRecipe.value = recipe;
                  controller.prefillFromRecipe(recipe!);
                }
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  useSafeArea: true,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) {
                    return DraggableScrollableSheet(
                      initialChildSize: 1,
                      maxChildSize: 1,
                      minChildSize: 0.5,
                      expand: false,
                      builder: (ctx, scrollCtrl) {
                        return UpdateAiInputsSheet(
                          scrollController: scrollCtrl,
                          onUpdated: () {
                            // Make the refined recipe (including its
                            // preserved id, see copyWithId) authoritative
                            // for this screen - the `recipe` getter here
                            // doesn't consult the shared controller, only
                            // _editableRecipe then the original prop.
                            setState(() {
                              _editableRecipe = controller.generatedRecipe.value;
                            });
                          },
                        );
                      },
                    );
                  },
                );
              },
              text: 'Update AI Inputs',
              isOutline: true,
            ),
          ),
        if (widget.fromAddRecipeScreen == false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CustomButton(
              fontSize: 13.5,
              onTap: () async {
                if (_isSavingExistingRecipe || recipe == null) return;
                setState(() => _isSavingExistingRecipe = true);
                try {
                  final r = recipe!;
                  final saved = await _recipeService.saveExistingRecipe(
                    id: r.id!,
                    servingTime: r.servingTime,
                    servings: r.servings,
                    category: r.category,
                    description: r.description,
                    dietaryHabits: r.dietaryHabits,
                    freeFrom: r.freeFrom,
                    ingredients: r.ingredients,
                    cookingSteps: r.cookingSteps,
                    nutrition: r.nutrition,
                    translations: r.translations,
                  );
                  if (saved) {
                    // Close the modal bottom sheet
                    if (mounted) Navigator.of(context).pop();
                    Get.snackbar(
                      'Success',
                      'Recipe saved successfully.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade100,
                      colorText: Colors.green.shade900,
                      duration: const Duration(seconds: 3),
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to save recipe. Please try again.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade900,
                      duration: const Duration(seconds: 3),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isSavingExistingRecipe = false);
                  }
                }
              },
              text: _isSavingExistingRecipe ? 'Saving...' : 'Save Recipe',
              isOutline: false,
              isLoading: _isSavingExistingRecipe,
            ),
          ),
      ],
    );
  }

  // ---------------- TAB ITEM ----------------
  Widget _buildTab(int index, String title) {
    final bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xffFDF2FA) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(index == 0 ? 22 : 0),
              bottomLeft: Radius.circular(index == 0 ? 22 : 0),
              topRight: Radius.circular(index == 2 ? 22 : 0),
              bottomRight: Radius.circular(index == 2 ? 22 : 0),
            ),
          ),
          alignment: Alignment.center,
          child: CustomText(
            fontSize: 13,
            text: title,

            color: isSelected ? Color(0xff530630) : Color(0xff384250),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------- DIVIDER ----------------
  Widget _verticalDivider() {
    return Container(
      width: 1.3,
      height: double.infinity,
      color: Color(0xff530630),
    );
  }
}
