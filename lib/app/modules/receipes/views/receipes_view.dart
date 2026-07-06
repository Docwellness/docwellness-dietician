import 'package:docwellnesdoc/app/modules/receipes/views/add_receipes.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/receipe_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/receipes_controller.dart';

class ReceipesView extends StatefulWidget {
  const ReceipesView({super.key});

  @override
  State<ReceipesView> createState() => _ReceipesViewState();
}

class _ReceipesViewState extends State<ReceipesView> {
  late final ReceipesController controller;

  @override
  void initState() {
    super.initState();
    // Ensure controller is registered
    if (!Get.isRegistered<ReceipesController>()) {
      Get.put(ReceipesController());
    }
    controller = Get.find<ReceipesController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        title: CustomText(
          text: 'Recipes & Supplements',
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              color: Color(0xffFEF6FB),
              child: Obx(() {
                // Default categories for global cuisines
                final defaultCategories = [
                  'All',
                  'Indian',
                  'American',
                  'British',
                  'Mediterranean',
                  'Asian',
                  'Italian',
                  'Mexican',
                  'Healthy Bowls',
                  'Smoothies & Drinks',
                  'High Protein',
                  'Keto',
                  'Vegan Specials',
                ];

                final categoryNames = controller.categories.isNotEmpty
                    ? controller.categories.map((c) => c.name).toList()
                    : defaultCategories;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: categoryNames.map((catName) {
                      final isSelected =
                          controller.selectedCategory.value == catName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => controller.changeCategory(catName),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xffFCCEEF)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xffFCCEEF)
                                    : const Color(0xffD2D6DB),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              catName,
                              style: GoogleFonts.roboto(
                                color: isSelected
                                    ? Color(0xff530630)
                                    : Color(0xff4D5761),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingRecipes.value &&
                  controller.recipes.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xffFCCEEF)),
                );
              }

              if (controller.recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        text: 'No recipes found',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: 'Add your first recipe!',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    controller.loadMoreRecipes();
                  }
                  return false;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount:
                        controller.recipes.length +
                        (controller.hasMoreRecipes.value ? 1 : 0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisExtent: 182,
                          crossAxisSpacing: 8,
                          crossAxisCount: 3,
                        ),
                    itemBuilder: (context, index) {
                      if (index == controller.recipes.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xffFCCEEF),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final recipe = controller.recipes[index];
                      return ReceipeContainer(
                        imageUrl: recipe.image ?? '',
                        title: recipe.name,
                        subTitle: '${recipe.ingredientsCount} ingredients',
                        onTap: () async {
                          // Fetch full recipe details and show in modal
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
                      );
                    },
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: CustomButton(
              onTap: () async {
                await Get.to(() => AddRecipeScreen());
                // Refresh recipes after returning from add screen
                controller.fetchRecipes(refresh: true);
              },
              text: 'Add New Recipe',
              isOutline: false,
            ),
          ),
        ],
      ),
    );
  }
}
