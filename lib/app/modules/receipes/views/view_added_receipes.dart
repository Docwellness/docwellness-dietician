import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/add_receipes.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ViewAddedReceipes extends StatefulWidget {
  final String categoryName;
  final String? categoryId;

  const ViewAddedReceipes({
    super.key,
    required this.categoryName,
    this.categoryId,
  });

  @override
  State<ViewAddedReceipes> createState() => _ViewAddedReceipesState();
}

class _ViewAddedReceipesState extends State<ViewAddedReceipes> {
  late final ReceipesController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ReceipesController>()) {
      Get.put(ReceipesController());
    }
    controller = Get.find<ReceipesController>();
    // Filter recipes by category
    controller.selectedCategory.value = widget.categoryName;
    controller.fetchRecipes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: widget.categoryName,
          fontWeight: FontWeight.w400,
          fontSize: 21,
          color: Color(0xff1F2A37),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRecipes.value &&
                  controller.recipes.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      CustomText(
                        text: 'No recipes found',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600]!,
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: 'Add a new recipe to get started',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[500]!,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: controller.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = controller.recipes[index];
                  return GestureDetector(
                    onTap: () async {
                      // Fetch full recipe details
                      final fullRecipe = await controller.fetchRecipeById(
                        recipe.id,
                      );
                      if (fullRecipe != null && context.mounted) {
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
                              builder: (ctx, scrollController) {
                                return RecipeDetailsScreen(
                                  fromAddRecipeScreen: false,
                                  scrollController: scrollController,
                                  recipePreview: fullRecipe,
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 24),
                          child: Row(
                            children: [
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFDF2FA),
                                  image:
                                      recipe.image != null &&
                                          recipe.image!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(recipe.image!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child:
                                    (recipe.image == null ||
                                        recipe.image!.isEmpty)
                                    ? const Center(
                                        child: Icon(
                                          Icons.restaurant_menu,
                                          size: 32,
                                          color: Color(0xffFCCEEF),
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: recipe.name.isNotEmpty
                                          ? recipe.name
                                          : 'Unnamed Recipe',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 18,
                                      color: Color(0xff384250),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    CustomText(
                                      text:
                                          '${recipe.ingredientsCount} ingredients • ${recipe.calories ?? 0} calories',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Color(0xff6C737F),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xffFDF2FA),
                                        border: Border.all(
                                          color: Color(0xffFCE7F6),
                                        ),
                                      ),
                                      child: CustomText(
                                        text: recipe.servingTime.isNotEmpty
                                            ? recipe.servingTime
                                            : recipe.cuisine,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Color(0xffEF45B2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xff4D5761),
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(color: Color(0xffFCCEEF)),
                        ),
                        SizedBox(height: 11),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomButton(
              onTap: () {
                Get.to(() => AddRecipeScreen());
              },
              text: 'Add New Recipe',
              isOutline: false,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
