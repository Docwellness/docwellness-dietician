import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/food_card_widget.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectDietSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String patientId;
  final String dietPlanId;
  const SelectDietSheet({
    super.key,
    required this.scrollController,
    required this.dietPlanId,
    required this.patientId,
  });

  @override
  State<SelectDietSheet> createState() => _SelectDietSheetState();
}

class _SelectDietSheetState extends State<SelectDietSheet>
    with SingleTickerProviderStateMixin {
  final PatientsController controller = Get.find<PatientsController>();

  late final TabController _tabController;

  // keep consistent order with your ButtonsTabBar tabs
  final List<String> _shifts = [
    "Breakfast",
    "Morning Drink",
    "Lunch",
    "Brunch",
    // "Morning Snacks",
    "Dinner",
    "Evening Snacks",
    "Night Drink",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _shifts.length, vsync: this);

    // set initial selectedShift from default
    controller.updateSelectedShift(_shifts[0]);

    // listen to tab changes and update controller
    _tabController.addListener(() {
      // only trigger when index changed (not while animating)
      if (!_tabController.indexIsChanging) {
        final shift = _shifts[_tabController.index];
        controller.updateSelectedShift(shift);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> getWeeksOfCurrentMonth() {
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;

    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0);

    int weekCount = 1;
    DateTime current = firstDay;

    List<String> weeks = [];

    while (current.isBefore(lastDay) || current.isAtSameMomentAs(lastDay)) {
      weeks.add("Week $weekCount");
      current = current.add(const Duration(days: 7));
      weekCount++;
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _shifts.length,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      height: 4,
                      width: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: const Color(0xff79747E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xff1F2A37),
                        ),
                      ),

                      // Week label (read-only)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Obx(
                          () => CustomText(
                            text: controller.selectedWeek.value,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: const Color(0xff1F2A37),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),
                  const Divider(color: Color(0xff9DA4AE)),
                  const SizedBox(height: 10),

                  PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ButtonsTabBar(
                        controller: _tabController,
                        radius: 8,
                        height: 38,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        backgroundColor: const Color(0xffFCCEEF),
                        borderWidth: 1,
                        borderColor: const Color(0xffFCCEEF),
                        labelStyle: GoogleFonts.roboto(
                          color: Color(0xff530630),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: GoogleFonts.roboto(
                          color: Color(0xff4D5761),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        unselectedBorderColor: const Color(0xffD2D6DB),
                        unselectedDecoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color(0xffD2D6DB),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tabs: _shifts.map((s) => Tab(text: s)).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // SHIFT-WISE MEAL LIST
                  Obx(() {
                    final meals = controller.shiftMeals;

                    if (meals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "No items for ${controller.selectedShift.value}",
                          style: const TextStyle(color: Color(0xff4D5761)),
                        ),
                      );
                    }

                    int currentWeekNumber = int.parse(
                      controller.selectedWeek.value.split(" ").last,
                    );

                    final selectedRecipesForWeek =
                        controller.weekSelectedRecipes[currentWeekNumber] ?? [];

                    return Column(
                      children: meals.map((meal) {
                        final recipe = controller.getRecipeById(meal.recipeId);

                        if (recipe == null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Card(
                              child: ListTile(
                                title: Text(meal.servingTime),
                                subtitle: Text(
                                  "Recipe not found: ${meal.recipeId}",
                                ),
                              ),
                            ),
                          );
                        }

                        final isSelected = selectedRecipesForWeek.contains(
                          recipe,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: FoodCard(
                            image: recipe.image,
                            name: recipe.name,
                            grams: "${recipe.totalWeightGrams}",
                            calorie: "${recipe.nutrition.calories}",
                            protein: "${recipe.nutrition.protein}",
                            fiber: "${recipe.nutrition.fiber}",
                            carbs: "${recipe.nutrition.carbs}",
                            fat: "${recipe.nutrition.fats}",
                            isSelected: isSelected,
                            onSelect: () =>
                                controller.toggleMealSelection(recipe),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  SizedBox(height: 16),
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: EdgeInsets.only(
                          top: 12,
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xffFDF2FA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: 'Total Budget',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xff851653),
                            ),

                            SizedBox(height: 14),
                            Divider(color: Color(0xffFCCEEF)),
                            SizedBox(height: 8),

                            infoRow(
                              "Calorie Budget",
                              "${controller.totalCalories.value.toStringAsFixed(0)} Cal",
                              'assets/icons/diet_icon_1.png',
                            ),

                            infoRow(
                              "Fat",
                              "${controller.totalFat.value.toStringAsFixed(0)} g",
                              'assets/icons/diet_icon_5.png',
                            ),

                            infoRow(
                              "Net Carbs",
                              "${controller.totalCarbs.value.toStringAsFixed(0)} g",
                              'assets/icons/diet_icon_6.png',
                            ),

                            infoRow(
                              "Protein",
                              "${controller.totalProtein.value.toStringAsFixed(0)} g",
                              'assets/icons/diet_icon_7.png',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // button — finalize only the selected week
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => CustomButton(
                isLoading: controller.showWeekDietSendingLoading.value,
                onTap: () async {
                  await controller.finalizeWeek(
                    widget.patientId,
                    widget.dietPlanId,
                    controller.selectedWeek.value,
                  );
                },
                text: 'Finalize Diet Plan for ${controller.selectedWeek.value}',
                isOutline: false,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(icon, height: 13, width: 13, fit: BoxFit.contain),
          SizedBox(width: 10),
          CustomText(
            text: label,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xff851653),
          ),
          Spacer(),
          CustomText(
            text: value,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
