import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateAiInputsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback onUpdated;

  UpdateAiInputsSheet({
    super.key,
    required this.scrollController,
    required this.onUpdated,
  });

  final ReceipesController controller = Get.find<ReceipesController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10, top: 10),
            decoration: BoxDecoration(
              color: const Color(0xff79747E),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              ),
              const SizedBox(width: 8),
              const CustomText(
                text: 'Update AI Inputs',
                fontWeight: FontWeight.w400,
                fontSize: 19,
                color: Color(0xff1F2A37),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xff9DA4AE)),

        // Scrollable form
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Recipe Name
              Obx(
                () => CustomField(
                  isPresent: controller.recipeNameHasError.value,
                  controller: controller.recipeNameController,
                  lable: 'Recipe Name',
                  onChange: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      controller.recipeNameHasError.value = false;
                    }
                  },
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
              ),
              const SizedBox(height: 20),

              // Recipe Language (multi-select)
              const CustomText(
                text: 'Recipe Language',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              const SizedBox(height: 10),
              Obx(() {
                const languages = ['English', 'Hindi', 'Marathi'];
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
              const SizedBox(height: 16),

              // Serving Time + Servings
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => CustomDropdown(
                        items: const [
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
                        suffixIconColor: const Color(0xff0D121C),
                        label: 'Serving Time',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        suffixIconColor: const Color(0xff0D121C),
                        label: 'Servings',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dietary Habits
              const CustomText(
                text: 'Dietary Habits',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              const SizedBox(height: 8),
              Obx(
                () => ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
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
                            color: const Color(0xff384250),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.toggleDietOption(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 31,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: item.isSelected
                                    ? const Color(0xff851653)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: item.isSelected
                                      ? const Color(0xff851653)
                                      : const Color(0xffCCCCCC),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: item.isSelected
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: item.isSelected
                                        ? Colors.white
                                        : const Color(0xffCCCCCC),
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
              const SizedBox(height: 11),

              // Free From
              const CustomText(
                text: 'Free From',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              const SizedBox(height: 8),
              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.freeFromOptions.length,
                  itemBuilder: (context, index) {
                    final item = controller.freeFromOptions[index];
                    return GestureDetector(
                      onTap: () {
                        item.isChecked = !item.isChecked;
                        controller.freeFromOptions.refresh();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: item.title,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xff384250),
                              ),
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
              const SizedBox(height: 16),

              // Custom Preferences
              CustomField(
                controller: controller.customPreferencesController,
                lable: 'Custom Ingredients/Preferences',
                hintText:
                    'Add a note for the AI (e.g., "High protein", "Make it spicy")',
              ),
              const SizedBox(height: 24),

              // Update button
              Obx(
                () => CustomButton(
                  onTap: () async {
                    if (controller.isUpdatingAi.value) return;
                    final result = await controller.updateAiInputs();
                    if (result != null) {
                      Get.back(); // Close this sheet
                      onUpdated(); // Callback to refresh the preview
                    }
                  },
                  text: controller.isUpdatingAi.value
                      ? 'Updating...'
                      : 'Update with AI',
                  isOutline: false,
                  isLoading: controller.isUpdatingAi.value,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
