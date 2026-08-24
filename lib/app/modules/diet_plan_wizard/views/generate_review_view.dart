import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/generate_review_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);
const _pillBg = Color(0xffFDF2FA);

/// Step 2 (Generate) "done" phase, plan-item mode only - shown inline by
/// generation_step_view.dart instead of the plain days-array checkmark
/// screen. Renders the just-generated V1 diet as a browsable, editable
/// day-group/serving-time grid (mirrors patients/views/select_diet_sheet.dart's
/// UX for the days-array flow) - recipe cards can be opened for full detail,
/// removed, swapped, or a new one added, before moving on to Step 3 (Refine
/// Portions, ingredient-level).
class GenerateReviewView extends StatelessWidget {
  const GenerateReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<GenerateReviewController>();

    return Obx(() {
      if (controller.loading.value && controller.weekDays.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: _primaryColor));
      }
      if (controller.errorMessage.value != null && controller.weekDays.isEmpty) {
        return Center(
          child: CustomText(text: controller.errorMessage.value!, fontWeight: FontWeight.w400, fontSize: 13, color: _mutedColor),
        );
      }

      final slot = controller.currentSlot;

      return Column(
        children: [
          const SizedBox(height: 8),
          const CustomText(text: 'Plan generated ✓', fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
          const SizedBox(height: 2),
          const CustomText(
            text: 'Version 1 of the diet. Add or remove recipes below.',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: _mutedColor,
          ),
          const SizedBox(height: 12),
          _PillRow(
            options: generateReviewDayGroups.map((dg) => MapEntry(dg, controller.dayGroupLabel(dg))).toList(),
            selected: controller.selectedDayGroup.value,
            onSelect: (dg) => controller.selectedDayGroup.value = dg,
          ),
          const SizedBox(height: 8),
          _PillRow(
            options: generateReviewServingTimes.map((t) => MapEntry(t, t)).toList(),
            selected: controller.selectedServingTime.value,
            onSelect: (t) => controller.selectedServingTime.value = t,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: slot == null
                ? const Center(
                    child: CustomText(text: 'No slot for this selection.', fontWeight: FontWeight.w400, fontSize: 12, color: _mutedColor),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...slot.items.map((item) => _ReviewRecipeCard(item: item, controller: controller)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openAddPicker(context, controller),
                        icon: const Icon(Icons.add, size: 18, color: _primaryColor),
                        label: const CustomText(text: 'Add Recipe', fontWeight: FontWeight.w500, fontSize: 13, color: _primaryColor),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: _primaryColor)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(onTap: wizard.nextStep, text: 'Continue', isOutline: false, buttonColor: _headerColor),
          ),
        ],
      );
    });
  }

  void _openAddPicker(BuildContext context, GenerateReviewController controller) {
    final slot = controller.currentSlot;
    if (slot == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecipePicker(
        title: 'Add Recipe',
        servingTime: controller.selectedServingTime.value,
        excludeRecipeIds: slot.items.map((i) => i.parentRecipeId).toSet(),
        onSelect: (recipe) => controller.addItem(recipe.id),
      ),
    );
  }
}

class _ReviewRecipeCard extends StatelessWidget {
  final WizardPlanItemV2 item;
  final GenerateReviewController controller;

  const _ReviewRecipeCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xffFAFAFA), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: item.recipeName, fontWeight: FontWeight.w500, fontSize: 13, color: _bodyColor),
                ],
              ),
            ),
            InkWell(
              onTap: () => _openSwapPicker(context),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.swap_horiz, size: 18, color: _primaryColor)),
            ),
            InkWell(
              onTap: () => controller.removeItem(item),
              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 18, color: _mutedColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final parentRecipeId = item.parentRecipeId;
    if (parentRecipeId.isEmpty) return;
    final recipe = await RecipeService().getRecipeById(parentRecipeId);
    if (recipe == null || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 1,
        maxChildSize: 1,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sheetScrollController) => RecipeDetailsScreen(
          fromAddRecipeScreen: false,
          scrollController: sheetScrollController,
          recipePreview: recipe,
        ),
      ),
    );
  }

  void _openSwapPicker(BuildContext context) {
    final slot = controller.currentSlot;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecipePicker(
        title: 'Swap Recipe',
        servingTime: controller.selectedServingTime.value,
        excludeRecipeIds: {item.parentRecipeId, ...?slot?.items.map((i) => i.parentRecipeId)},
        onSelect: (recipe) => controller.swapItem(item, recipe.id),
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final List<MapEntry<String, String>> options;
  final String selected;
  final void Function(String) onSelect;

  const _PillRow({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = options[index];
          final isSelected = entry.key == selected;
          return InkWell(
            onTap: () => onSelect(entry.key),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : _pillBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: CustomText(
                text: entry.value,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: isSelected ? Colors.white : _primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecipePicker extends StatefulWidget {
  final String title;
  final String servingTime;
  final Set<String> excludeRecipeIds;
  final void Function(RecipeListItem recipe) onSelect;

  const _RecipePicker({required this.title, required this.servingTime, required this.excludeRecipeIds, required this.onSelect});

  @override
  State<_RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends State<_RecipePicker> {
  final RecipeService _recipeService = RecipeService();
  List<RecipeListItem> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _recipeService.listRecipes(servingTime: widget.servingTime, limit: 50);
    if (!mounted) return;
    setState(() {
      _recipes = response.recipes.where((r) => !widget.excludeRecipeIds.contains(r.id)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(text: widget.title, fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: _primaryColor)),
              )
            else if (_recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CustomText(text: 'No other recipes for this slot.', fontWeight: FontWeight.w400, fontSize: 13, color: _mutedColor),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _recipes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return ListTile(
                      title: CustomText(text: recipe.name, fontWeight: FontWeight.w500, fontSize: 14, color: _bodyColor),
                      onTap: () {
                        widget.onSelect(recipe);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
