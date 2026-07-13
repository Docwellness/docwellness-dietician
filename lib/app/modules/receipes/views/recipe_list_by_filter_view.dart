import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/receipe_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/receipes_controller.dart';

/// Flat, paginated grid of individual recipes for one landing-grid card
/// (a specific serving time within the current top category, or the
/// Supplements shortcut) - this is the same grid/pagination/recipe-details
/// flow the old single-screen ReceipesView used to render inline, now
/// reused as a drill-down destination.
class RecipeListByFilterView extends StatefulWidget {
  final String title;
  final String topCategory;
  final String? servingTime;
  final String? tag;

  const RecipeListByFilterView({
    super.key,
    required this.title,
    required this.topCategory,
    required this.servingTime,
    this.tag,
  });

  @override
  State<RecipeListByFilterView> createState() =>
      _RecipeListByFilterViewState();
}

class _RecipeListByFilterViewState extends State<RecipeListByFilterView> {
  final ReceipesController controller = Get.find<ReceipesController>();

  @override
  void initState() {
    super.initState();
    // selectedCategory is a separate exact-match filter the shared
    // ReceipesController also carries (for ViewAddedReceipes's dashboard
    // quick-links) - reset it here so a stale value doesn't silently
    // combine with this screen's filters and return zero results.
    // topCategory is passed as an explicit fetchRecipes override rather
    // than written into the shared selectedTopCategory Rx, since that Rx
    // is watched by the landing page's Obx which stays mounted underneath
    // this drill-down (Get.to doesn't dispose it) - mutating it here during
    // initState previously caused "setState() called during build" on the
    // still-building landing page.
    controller.selectedCategory.value = 'All';
    controller.fetchRecipes(
      refresh: true,
      servingTime: widget.servingTime,
      tag: widget.tag,
      topCategory: widget.topCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: widget.title,
          color: const Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingRecipes.value && controller.recipes.isEmpty) {
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
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              controller.loadMoreRecipes();
            }
            return false;
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GridView.builder(
              itemCount:
                  controller.recipes.length +
                  (controller.hasMoreRecipes.value ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: 192,
                mainAxisSpacing: 8,
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
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ReceipeContainer(
                      imageUrl: recipe.image ?? '',
                      title: recipe.name,
                      subTitle: '${recipe.ingredientsCount} ingredients',
                      imageWidth: constraints.maxWidth,
                      onTap: () async {
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
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
