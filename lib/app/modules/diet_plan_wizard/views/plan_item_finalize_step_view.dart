import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/recipe_details.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/day_group_label.dart';
import 'package:docwellnesdoc/app/utils/functions/quantity_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/plan_item_finalize_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';
import '../widgets/wizard_theme.dart';
import '../widgets/wizard_widgets.dart';

/// Step 5 (Review & Finalize), v4.0 mode. A day-group-selectable meal
/// timeline that previews the plan in the patient Diet Plan view's own
/// visual language (portion pill, per-recipe macros, timeline rail), with
/// cooking steps tucked behind a per-card expand - while keeping the
/// per-day-group +/-5% calorie-tolerance gate that guards activation
/// (openspec change diet-wizard-portions-and-polish,
/// diet-plan-wizard/finalize-step).
class PlanItemFinalizeStepView extends StatelessWidget {
  const PlanItemFinalizeStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<PlanItemFinalizeStepController>();

    if (wizard.dietPlanId.value == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CustomText(
            text: 'Generate a plan first before finalizing.',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: WizardPalette.muted,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator(color: WizardPalette.magenta));
      }
      if (controller.errorMessage.value != null && controller.weekDays.isEmpty) {
        return Center(
          child: CustomText(
            text: controller.errorMessage.value!,
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: WizardPalette.muted,
          ),
        );
      }

      final selectableDayGroups = controller.selectableDayGroups;
      final day = controller.selectedDay;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  CustomText(
                    text: controller.isAlreadyFinalized ? 'Diet Plan' : 'Review & Finalize',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: WizardPalette.plum,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: controller.isAlreadyFinalized
                        ? 'Exactly what your patient sees - refine portions, or regenerate for a fresh AI plan.'
                        : 'Exactly what will be prescribed - review each day before confirming.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: WizardPalette.muted,
                  ),
                  const SizedBox(height: 14),
                  if (controller.targetCalories != null) _CalorieChecklist(controller: controller),
                  if (selectableDayGroups.length > 1) ...[
                    const SizedBox(height: 8),
                    DayGroupSelector(
                      options: selectableDayGroups,
                      selected: controller.selectedDayGroup.value,
                      onSelect: (dg) => controller.selectedDayGroup.value = dg,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (day != null) _DayTimeline(day: day, controller: controller),
                  if (controller.errorMessage.value != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CustomText(
                        text: controller.errorMessage.value!,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: WizardPalette.warn,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Obx(() {
            // Keep this Obx subscribed to a real observable - isAlreadyFinalized
            // reads a plain cache getter and the true-branch below wouldn't
            // otherwise touch anything reactive, which trips GetX's
            // "improper use of a GetX" guard.
            final finalizing = controller.finalizing.value;
            final canActivate = controller.canActivate;
            // Reopened from the profile's Weekly Diet Plans row: this plan
            // is already finalized, so instead of "Finalize" the actions
            // are to Refine the portions or Regenerate the whole plan.
            if (controller.isAlreadyFinalized) {
              return WizardStepFooter(
                primaryLabel: 'Refine Plan',
                onPrimary: () => wizard.goToStep(3),
                secondaryLabel: 'Regenerate Plan',
                onSaveExit: () => _confirmRegenerate(context, wizard),
              );
            }
            return WizardStepFooter(
              primaryLabel: 'Finalize Plan',
              primaryLoading: finalizing,
              primaryDisabled: !canActivate,
              onSaveExit: () => Get.back(),
              onPrimary: () async {
                final ok = await controller.finalizePlan();
                if (!ok) return;
                if (context.mounted) {
                  showAppToast(
                    context,
                    message: 'Plan finalized. It goes live once the patient\'s payment is confirmed.',
                    type: AppToastType.success,
                  );
                }
                Get.back();
              },
            );
          }),
        ],
      );
    });
  }

  /// "Regenerate Plan": confirm (it discards every current recipe and any
  /// hand-tuned portions), then send the dietician back to Targets with a
  /// flag the Generation step consumes to re-run the AI menu.
  Future<void> _confirmRegenerate(BuildContext context, WizardController wizard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CustomText(text: 'Regenerate this plan?', fontWeight: FontWeight.w600, fontSize: 16, color: WizardPalette.plum),
        content: const CustomText(
          text: 'The current recipes and any portion edits are replaced with a fresh AI selection. You can adjust the calorie and macro targets first. This cannot be undone.',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: WizardPalette.ink,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const CustomText(text: 'Cancel', fontWeight: FontWeight.w500, fontSize: 13, color: WizardPalette.muted),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const CustomText(text: 'Regenerate', fontWeight: FontWeight.w600, fontSize: 13, color: WizardPalette.plum),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    wizard.regenerateRequested = true;
    wizard.goToStep(1);
  }
}

class _CalorieChecklist extends StatelessWidget {
  final PlanItemFinalizeStepController controller;

  const _CalorieChecklist({required this.controller});

  @override
  Widget build(BuildContext context) {
    final target = controller.targetCalories!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...controller.dayCalorieChecks.map(
          (check) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  check.withinTolerance ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: check.withinTolerance ? WizardPalette.ok : WizardPalette.warn,
                ),
                const SizedBox(width: 6),
                CustomText(
                  text: '${dayGroupLabel(check.dayGroup)}: ${check.totalCalories.round()} cal (target ${target.round()} cal)',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: check.withinTolerance ? WizardPalette.muted : WizardPalette.warn,
                ),
              ],
            ),
          ),
        ),
        if (!controller.canActivate)
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 4),
            child: CustomText(
              text: 'Every day must be within ±5% of the calorie target before this plan can be finalized.',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: WizardPalette.warn,
            ),
          ),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final WizardDayGroupV2 day;
  final PlanItemFinalizeStepController controller;

  const _DayTimeline({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    final meals = day.meals.where((m) => m.items.isNotEmpty || m.supplements.isNotEmpty).toList();
    if (meals.isEmpty) {
      return const CustomText(
        text: 'No meals generated for this day yet.',
        fontWeight: FontWeight.w400,
        fontSize: 13,
        color: WizardPalette.muted,
      );
    }
    return MealTimeline(
      slots: meals
          .map(
            (meal) => (
              servingTime: meal.servingTime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in meal.items) ...[
                    _RecipeCard(item: item, servingTime: meal.servingTime),
                    const SizedBox(height: 8),
                  ],
                  for (final supplement in meal.supplements)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SupplementRow(supplement: supplement),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final WizardPlanItemV2 item;
  final String servingTime;

  const _RecipeCard({required this.item, required this.servingTime});

  String? get _portionLabel {
    final components = item.recipeVersion?.components ?? const [];
    if (components.isEmpty) return null;
    return components.map((c) {
      final formatted = formatQuantityLabel(c.quantity.toStringAsFixed(2), c.unit);
      if (components.length > 1 && c.label != item.recipeName) return '${c.label}: $formatted';
      return formatted;
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final version = item.recipeVersion;
    final n = item.calculatedNutrition ?? version?.nutritionPerServing;
    num? macro(String key) => (n?[key] as num?);

    return WizardRecipeCard(
      title: item.recipeName,
      portionLabel: _portionLabel,
      calories: item.calories?.round(),
      versionLabel: version != null ? 'V${version.versionNumber}' : null,
      pinned: item.pinned,
      onTap: item.parentRecipeId.isEmpty ? null : () => _openRecipeDetails(context),
      macros: n == null
          ? null
          : MacroChipRow(protein: macro('protein'), fiber: macro('fiber'), carbs: macro('carbs'), fat: macro('fats')),
    );
  }

  /// Opens the shared Recipe Details bottom sheet for this plan item, showing
  /// its actually-assigned recipe version's ingredients / components / steps /
  /// nutrition (not the master Recipe's stale values). Read-only here:
  /// Finalize is a review step, so no save/apply callbacks are wired.
  ///
  /// The version's data (already in hand from GET .../plan-items) is enough
  /// to render this sheet, so it opens instantly - no blocking GET
  /// /recipes/:id round-trip. The master Recipe is only fetched as a
  /// fallback when a card somehow has no resolved version yet.
  Future<void> _openRecipeDetails(BuildContext context) async {
    final version = item.recipeVersion;
    RecipePreview recipeToShow;
    if (version != null && version.ingredients.isNotEmpty) {
      recipeToShow = version.toRecipePreview(servingTime: servingTime);
    } else {
      final recipe = await RecipeService().getRecipeById(item.parentRecipeId);
      if (recipe == null || !context.mounted) return;
      recipeToShow = recipe;
    }
    if (!context.mounted) return;

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
          isPlanItemPreview: true,
          scrollController: sheetScrollController,
          recipePreview: recipeToShow,
        ),
      ),
    );
  }
}

class _SupplementRow extends StatelessWidget {
  final WizardSupplement supplement;

  const _SupplementRow({required this.supplement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WizardPalette.surface,
        borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
        border: Border.all(color: WizardPalette.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined, size: 15, color: WizardPalette.muted),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              text:
                  '${supplement.supplementName ?? 'Supplement'}${supplement.dosage != null ? ' · ${supplement.dosage}' : ''} (${supplement.timingAnchor})',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: WizardPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
