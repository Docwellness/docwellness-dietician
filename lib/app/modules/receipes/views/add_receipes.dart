import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  late final ReceipesController controller;

  @override
  void initState() {
    super.initState();
    // Ensure controller is registered before using it
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
        elevation: 0,
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: CustomText(
          text: "Add recipe",
          fontSize: 21,
          color: Color(0xff1F2A37),
          fontWeight: FontWeight.w400,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              CustomField(
                isPresent: true,
                controller: controller.recipeNameController,
                lable: 'Recipe Name',
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Image.asset(
                    'assets/icons/icon.png',
                    height: 20,
                    width: 20,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              CustomText(
                text: 'Recipe Language',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              SizedBox(height: 10),
              Obx(() {
                final languages = ['English', 'Hindi', 'Marathi'];
                return Row(
                  children: languages.map((lang) {
                    final isSelected = controller.selectedLanguages.contains(
                      lang,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => controller.toggleLanguage(lang),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff851653)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xff851653)
                                  : const Color(0xffCCCCCC),
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            lang,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xff384250),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => CustomDropdown(
                        items: [
                          'Morning Drink',
                          'Breakfast',
                          'Brunch',
                          'Lunch',
                          'Evening Snack',
                          'Dinner',
                          'Night Drink',
                        ],
                        value: controller.selectedServingTime.value,
                        onChanged: (value) {
                          controller.selectedServingTime.value = value!;
                        },
                        isRounded: false,
                        suffixIconColor: Color(0xff0D121C),
                        label: 'Serving Time',
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 122,
                    child: Obx(
                      () => CustomDropdown(
                        items: List.generate(50, (index) => "${index + 1}"),
                        value: controller.selectedServingCount.value,
                        onChanged: (value) {
                          controller.selectedServingCount.value = value!;
                        },
                        isRounded: false,
                        suffixIconColor: Color(0xff0D121C),
                        label: 'Servings',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              CustomText(
                text: 'Dietary Habits',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              SizedBox(height: 8),
              Obx(
                () => ListView.builder(
                  physics: NeverScrollableScrollPhysics(),

                  itemCount: controller.dietOptions.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final item = controller.dietOptions[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: item.name,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            color: Color(0xff384250),
                          ),

                          // Custom switch
                          GestureDetector(
                            onTap: () {
                              item.isSelected = !item.isSelected;
                              controller.dietOptions.refresh();

                              debugPrint(
                                '------------------- ${controller.selectedOptions}',
                              );
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              width: 60,
                              height: 31,
                              padding: EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: item.isSelected
                                    ? Color(0xff851653)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: item.isSelected
                                      ? Color(0xff851653)
                                      : Color(0xffCCCCCC),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: AnimatedAlign(
                                duration: Duration(milliseconds: 200),
                                alignment: item.isSelected
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: item.isSelected
                                        ? Colors.white
                                        : Color(0xffCCCCCC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 11),
              CustomText(
                text: 'Free From',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              SizedBox(height: 8),

              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.freeFromOptions.length,
                  itemBuilder: (context, index) {
                    final item = controller.freeFromOptions[index];

                    return GestureDetector(
                      onTap: () {
                        item.isChecked = !item.isChecked;
                        controller.freeFromOptions.refresh();
                      },
                      child: SizedBox(
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              text: item.title,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff384250),
                            ),
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    item.isChecked
                                        ? 'assets/icons/Checkboxes(1) copy.png'
                                        : 'assets/icons/Checkboxes copy.png',
                                  ),
                                  colorFilter: item.isChecked
                                      ? null
                                      : const ColorFilter.mode(
                                          Color(0xffCCCCCC),
                                          BlendMode.srcIn,
                                        ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              CustomField(
                controller: controller.customPreferencesController,
                lable: 'Custom Ingredients/Preferences',
                hintText:
                    'Add a note for the AI (e.g., "High protein", "Make it spicy")',
              ),
              SizedBox(height: 32),
              Obx(
                () => CustomButton(
                  onTap: () async {
                    if (controller.isGenerating.value) return;
                    final recipe = await controller.generateRecipePreview();
                    if (recipe != null) {
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
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 1,
                            maxChildSize: 1,
                            minChildSize: 0.5,
                            expand: false,
                            builder: (context, scrollController) {
                              return RecipeDetailsScreen(
                                fromAddRecipeScreen: true,
                                scrollController: scrollController,
                                recipePreview: recipe,
                              );
                            },
                          );
                        },
                      );
                    }
                  },
                  text: controller.isGenerating.value
                      ? 'Generating...'
                      : 'Show AI Magic',
                  isOutline: false,
                  isLoading: controller.isGenerating.value,
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
