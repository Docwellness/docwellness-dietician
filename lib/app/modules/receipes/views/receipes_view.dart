import 'package:docwellnesdoc/app/modules/receipes/views/add_receipes.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_list_by_filter_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/receipes_controller.dart';

/// Landing screen for the "Receipes" bottom-nav tab: a top-level cuisine
/// filter (All/Indian/Continental/Western/Supplements - a curated grouping
/// over the full 24-value Recipe.category enum, see
/// utils/recipeCategoryGroups.js) followed by a grid of real, per-serving-
/// time recipe counts, plus a Supplements shortcut card. Tapping a card
/// drills into RecipeListByFilterView's flat recipe grid.
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
    if (!Get.isRegistered<ReceipesController>()) {
      Get.put(ReceipesController());
    }
    controller = Get.find<ReceipesController>();
    // Shared controller singleton - reset the exact-category filter (only
    // used by ViewAddedReceipes's dashboard quick-links) so it can't leak
    // into this screen's topCategory-based summary fetch.
    controller.selectedCategory.value = 'All';
    controller.fetchServingTimeSummary();
  }

  static const _headerColor = Color(0xffFDF2FA);
  static const _accent = Color(0xff851653);

  // Meal-appropriate icon + tint per serving time - no photos exist in this
  // app for meal categories, so cards use this app's established icon +
  // colored-container visual language (matching e.g. the patient profile's
  // Basic Information/BMI card icons) instead.
  static const Map<String, IconData> _servingTimeIcons = {
    'Morning Drink': Icons.emoji_food_beverage_outlined,
    'Breakfast': Icons.breakfast_dining_outlined,
    'Brunch': Icons.brunch_dining_outlined,
    'Lunch': Icons.lunch_dining_outlined,
    'Evening Snack': Icons.cookie_outlined,
    'Dinner': Icons.dinner_dining_outlined,
    'Night Drink': Icons.nightlight_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        title: CustomText(
          text: 'Recipes & Supplements',
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
          fontSize: 21,
        ),
      ),
      body: Column(
        children: [
          // Top-level category chip strip lives directly in the body (not
          // AppBar.bottom) so its background always matches the AppBar
          // exactly and its left inset lines up with the title above it.
          Container(
            width: double.infinity,
            color: _headerColor,
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ReceipesController.topCategories.map((catName) {
                    final isSelected =
                        controller.selectedTopCategory.value == catName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => controller.changeTopCategory(catName),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Obx(
              () => CustomText(
                text: '${controller.totalRecipeCount} recipe${controller.totalRecipeCount == 1 ? '' : 's'} total',
                color: const Color(0xff6C737F),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingServingTimeSummary.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xffFCCEEF)),
                );
              }

              final summary = controller.servingTimeSummary.value;
              // 7 real serving-time buckets + the Supplements shortcut card.
              final cards = [
                ..._servingTimeIcons.keys.map(
                  (st) => _CategoryCardData(
                    title: st,
                    count: summary.countFor(st),
                    icon: _servingTimeIcons[st]!,
                    onTap: () => Get.to(
                      () => RecipeListByFilterView(
                        title: st,
                        topCategory: controller.selectedTopCategory.value,
                        servingTime: st,
                      ),
                    ),
                  ),
                ),
                _CategoryCardData(
                  title: 'Supplements',
                  count: summary.supplementsCount,
                  icon: Icons.medication_outlined,
                  onTap: () => Get.to(
                    () => const RecipeListByFilterView(
                      title: 'Supplements',
                      topCategory: 'Supplements',
                      servingTime: null,
                    ),
                  ),
                ),
                _CategoryCardData(
                  title: 'Sides',
                  count: summary.sidesCount,
                  icon: Icons.rice_bowl_outlined,
                  onTap: () => Get.to(
                    () => const RecipeListByFilterView(
                      title: 'Sides',
                      topCategory: 'All',
                      servingTime: null,
                      tag: 'side',
                    ),
                  ),
                ),
                _CategoryCardData(
                  title: 'Salad',
                  count: summary.saladCount,
                  icon: Icons.eco_outlined,
                  onTap: () => Get.to(
                    () => const RecipeListByFilterView(
                      title: 'Salad',
                      topCategory: 'All',
                      servingTime: null,
                      tag: 'salad',
                    ),
                  ),
                ),
              ];

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 130,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: card.onTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffFCE7F6)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xffFCE7F6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(card.icon, color: _accent, size: 20),
                          ),
                          const Spacer(),
                          CustomText(
                            text: card.title,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xff1F2A37),
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            text:
                                '${card.count} recipe${card.count == 1 ? '' : 's'}',
                            fontWeight: FontWeight.w400,
                            fontSize: 11,
                            color: const Color(0xff6C737F),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              onTap: () async {
                await Get.to(() => AddRecipeScreen());
                controller.fetchServingTimeSummary();
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

class _CategoryCardData {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  _CategoryCardData({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });
}
