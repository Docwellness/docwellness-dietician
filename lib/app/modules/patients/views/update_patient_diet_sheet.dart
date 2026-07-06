import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/food_card_widget.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdatePatientDietSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String patientId;
  const UpdatePatientDietSheet({
    super.key,
    required this.scrollController,
    required this.patientId,
  });

  @override
  State<UpdatePatientDietSheet> createState() => _SelectDietSheetState();
}

class _SelectDietSheetState extends State<UpdatePatientDietSheet> {
  final PatientsController controller = Get.find<PatientsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.showSelectedDeitLoading.value == true) {
        return Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        );
      }

      if (controller.dietPlanWeekData.value == null) {
        return Center(child: Text("No data found"));
      }

      return _buildDietContent();
    });
  }

  Widget _buildDietContent() {
    final summary = controller.dietPlanWeekData.value?.summary;

    return DefaultTabController(
      length: 7,
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

                      CustomText(
                        text:
                            "Week ${controller.dietPlanWeekData.value!.week.toString()}",
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                        color: Color(0xff1F2A37),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.more_vert_sharp, color: Colors.black),
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

                        tabs: const [
                          Tab(text: "Breakfast"),
                          Tab(text: "Morning Drink"),
                          Tab(text: "Lunch"),
                          Tab(text: "Brunch"),
                          Tab(text: "Dinner"),
                          Tab(text: "Evening Snacks"),
                          Tab(text: "Night Drink"),
                        ],
                        onTap: (index) {
                          final shifts = [
                            "Breakfast",
                            "Morning Drink",
                            "Lunch",
                            "Brunch",
                            "Dinner",
                            "Evening Snack",
                            "Night Drink",
                          ];

                          final chosen = shifts[index];
                          controller.getSelectedShift.value = chosen;
                          controller.updateGetShiftMeals();
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  Obx(() {
                    if (controller.getShiftMeals.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "No items for ${controller.getSelectedShift.value}",
                          style: TextStyle(color: Color(0xff4D5761)),
                        ),
                      );
                    }

                    return Column(
                      children: controller.getShiftMeals.map((recipe) {
                        final nutrition = recipe.nutrition;
                        final servingSize = recipe.servingSize;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: FoodCard(
                            name: recipe.name,
                            grams:
                                "${servingSize.quantity}${servingSize.unit.toUpperCase()}",
                            calorie: "${nutrition.calories}",
                            protein: "${nutrition.protein}",
                            fiber: "${nutrition.fiber}",
                            carbs: "${nutrition.carbs}",
                            fat: "${nutrition.fats}",
                            isSelected: recipe.isSelected,
                            onSelect: () {
                              // toggle selection for this recipe
                              controller.toggleRecipeSelection(recipe.id);
                            },
                            nextWeekTag: recipe.nextWeekTag,
                            image: recipe.image,
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(
                      () => Container(
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
                              '${controller.selectedCalories.value} Cal',
                              'assets/icons/diet_icon_1.png',
                              "${summary?.totalCalories ?? 0}",
                            ),

                            infoRow(
                              "Fat",
                              '${controller.selectedFat.value.toStringAsFixed(1)} g',
                              'assets/icons/diet_icon_5.png',
                              '${summary?.fatPercent ?? 0}% (${summary?.fatGrams ?? 0} g)',
                            ),
                            infoRow(
                              "Net Carbs",
                              '${controller.selectedCarbs.value.toStringAsFixed(1)} g',
                              'assets/icons/diet_icon_6.png',
                              '${summary?.carbPercent ?? 0}% (${summary?.carbGrams ?? 0} g)',
                            ),
                            infoRow(
                              "Protein",
                              '${controller.selectedProtein.value.toStringAsFixed(1)} g',
                              'assets/icons/diet_icon_7.png',
                              '${summary?.proteinPercent ?? 0}% (${summary?.proteinGrams ?? 0} g)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => CustomButton(
                isLoading: controller.updatingWeekItem.value,
                onTap: () async {
                  await controller.updateSelectedDiet(
                    widget.patientId,
                    controller.dietPlanWeekData.value?.dietPlanId ?? "",
                    controller.dietPlanWeekData.value?.week ?? 0,
                  );
                },
                text:
                    'Update Selections for ${controller.getSelectedShift.value}',
                isOutline: false,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomButton(
              onTap: () {},
              text: 'Find more ${controller.getSelectedShift.value}',
              isOutline: true,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget infoRow(
    String label,
    String pastValue,
    String icon,
    String currentValue,
  ) {
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
            text: "$currentValue ",
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xff9DA4AE),
          ),
          CustomText(
            text: pastValue,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
