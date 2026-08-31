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

  /// Add a new ingredient, or (when [editIndex] is given) edit the one at
  /// that position - renaming an ingredient here is how you fix one that
  /// doesn't match the food library so it resolves on the next save.
  void _showIngredientDialog(BuildContext context, {int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit
        ? controller.generatedRecipe.value?.ingredients[editIndex]
        : null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final quantityController =
        TextEditingController(text: existing != null ? '${existing.quantity}' : '');
    const units = ['g', 'ml', 'tsp', 'tbsp', 'cup', 'piece'];
    String unit = units.contains(existing?.unit) ? existing!.unit : 'g';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Ingredient' : 'Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: unit,
                    items: units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (u) {
                      if (u != null) setDialogState(() => unit = u);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final quantity = num.tryParse(quantityController.text.trim());
                if (name.isEmpty || quantity == null) return;
                if (isEdit) {
                  controller.updateIngredientAtEdit(
                    editIndex,
                    name: name,
                    quantity: quantity,
                    unit: unit,
                  );
                } else {
                  controller.addIngredientToEdit(name: name, quantity: quantity, unit: unit);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

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

              // Ingredients (add/remove) - what the AI actually re-runs
              // nutrition/recipe generation against, see
              // ReceipesController.updateAiInputs's ingredients: currentRecipe.ingredients.
              const CustomText(
                text: 'Ingredients',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final ingredients = controller.generatedRecipe.value?.ingredients ?? [];
                return Column(
                  children: [
                    for (var i = 0; i < ingredients.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _showIngredientDialog(context, editIndex: i),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CustomText(
                                        text: '${ingredients[i].name} · ${ingredients[i].quantity} ${ingredients[i].unit}',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: const Color(0xff384250),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.edit_outlined, size: 16, color: Color(0xff851653)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => controller.removeIngredientFromEdit(i),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close, size: 18, color: Color(0xff6C737F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _showIngredientDialog(context),
                      icon: const Icon(Icons.add, size: 18, color: Color(0xff851653)),
                      label: const CustomText(
                        text: 'Add Ingredient',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xff851653),
                      ),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xff851653))),
                    ),
                  ],
                );
              }),
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
