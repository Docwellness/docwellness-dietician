import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/finalize_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';
import '../widgets/wizard_theme.dart';
import '../widgets/wizard_widgets.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);
const _warnColor = Color(0xffB45309);
const _okColor = Color(0xff059669);

/// Step 5 (Finalize & Exception Review) - see finalize_step_controller.dart
/// for why this has two sub-states (draft review, then a read-only
/// post-finalize summary - Week Tweak/Swap vs Scale were removed as part of
/// v4.0's hard cutover).
class FinalizeStepView extends StatelessWidget {
  const FinalizeStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<FinalizeStepController>();

    if (wizard.dietPlanId.value == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CustomText(
            text: 'Generate a plan first (Step 4) before finalizing.',
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: _mutedColor,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator(color: _primaryColor));
      }
      if (controller.errorMessage.value != null && controller.weekDays.isEmpty) {
        return Center(
          child: CustomText(
            text: controller.errorMessage.value!,
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: _mutedColor,
          ),
        );
      }
      return controller.isFinalized.value
          ? _CleverAdjustmentsView(controller: controller)
          : _DraftReviewView(controller: controller);
    });
  }
}

class _DraftReviewView extends StatelessWidget {
  final FinalizeStepController controller;

  const _DraftReviewView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const CustomText(
                  text: 'Review the generated week',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: _headerColor,
                ),
                const SizedBox(height: 4),
                const CustomText(
                  text: 'Finalizing locks this week\'s meals. The plan is activated later, once the patient\'s payment is confirmed.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: _mutedColor,
                ),
                const SizedBox(height: 16),
                Obx(
                  () => Column(
                    children: controller.draftDayGroups.map((dayGroup) {
                      final selected = <String>[];
                      for (final st in (dayGroup['servingTimes'] as List? ?? [])) {
                        for (final r in (st['recipes'] as List? ?? [])) {
                          if (r['isSelected'] == true) {
                            selected.add('${st['servingTime']}: ${r['name']}');
                          }
                        }
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffFDF2FA)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: dayGroup['dayGroup'] ?? '',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _bodyColor,
                            ),
                            const SizedBox(height: 6),
                            if (selected.isEmpty)
                              const CustomText(
                                text: 'Nothing selected yet.',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: _mutedColor,
                              )
                            else
                              ...selected.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: CustomText(
                                    text: s,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: _bodyColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CustomText(
                      text: controller.errorMessage.value!,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: const Color(0xffDC2626),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => CustomButton(
              isLoading: controller.finalizing.value,
              onTap: controller.finalizeThisWeek,
              text: 'Finalize This Week',
              isOutline: false,
              buttonColor: _headerColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// The read-only "here's the diet plan" view for an already-finalized
/// days-array week - deliberately built from the same shared widgets
/// (DayGroupSelector, day nutrition card, MealTimeline, WizardRecipeCard)
/// as PlanItemFinalizeStepView's own already-finalized state, so the two
/// read identically to the dietician regardless of which dataModel the
/// plan underneath happens to be. Previously this was a collapsed-by-
/// default list of calorie-deviation warnings (Zone 2/3's "Exception
/// Review") - useful as an audit tool, but it hid the actual meals behind
/// a chevron and read as a list of problems rather than a diet plan; the
/// per-day balance check is now a small inline badge instead, and the
/// meals themselves are always visible.
class _CleverAdjustmentsView extends StatelessWidget {
  final FinalizeStepController controller;

  const _CleverAdjustmentsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final selectableDayGroups = controller.selectableDayGroups;
            final day = controller.selectedDay;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const CustomText(
                    text: 'Diet Plan',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: WizardPalette.plum,
                  ),
                  if (selectableDayGroups.length > 1) ...[
                    const SizedBox(height: 12),
                    DayGroupSelector(
                      options: selectableDayGroups,
                      selected: controller.selectedDayGroup.value,
                      onSelect: (dg) => controller.selectedDayGroup.value = dg,
                    ),
                  ],
                  if (day != null && day.hasItems) ...[
                    const SizedBox(height: 12),
                    _DayNutritionCard(day: day, controller: controller),
                  ],
                  const SizedBox(height: 16),
                  if (day != null) _DayTimeline(day: day),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                final status = controller.wizard.patientsController.patientProfileModel.value?.status;
                // "Goes live once payment is confirmed" is only true for a
                // just-finalized plan still waiting on activation - reopening
                // an already-Active (payment already confirmed) week to
                // review it kept showing that same stale line regardless.
                final isLive = status?.activeDietPlanStatus == 'Active' &&
                    status?.activeDietPlanId == controller.dietPlanId;
                return CustomText(
                  text: isLive
                      ? 'This week is finalized and live - the patient can already see and log it.'
                      : 'This week is finalized. The plan goes live once the patient\'s payment is confirmed.',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: _mutedColor,
                );
              }),
              const SizedBox(height: 10),
              CustomButton(
                onTap: () => Get.back(),
                text: 'Done',
                isOutline: false,
                buttonColor: _headerColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Total calories + macros for the currently-selected day-group, plus a
/// small balance badge against calorieExceptions (the days-array system's
/// own calorie-tolerance check - see finalize_step_controller.dart's
/// loadExceptions) - kept as a useful signal, just no longer gating
/// whether the day's actual meals are visible.
class _DayNutritionCard extends StatelessWidget {
  final WizardDayGroup day;
  final FinalizeStepController controller;

  const _DayNutritionCard({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      WizardCalorieException? exception;
      for (final e in controller.calorieExceptions) {
        if (e.dayGroup == day.dayGroup) {
          exception = e;
          break;
        }
      }
      final isBalanced = exception == null;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WizardPalette.surface,
          borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
          border: Border.all(color: WizardPalette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CustomText(
                  text: '${day.totalCalories.round()}',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: WizardPalette.plum,
                ),
                const SizedBox(width: 4),
                const CustomText(
                  text: 'cal / day',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: WizardPalette.muted,
                ),
                const Spacer(),
                Icon(
                  isBalanced ? Icons.check_circle : Icons.warning_rounded,
                  size: 14,
                  color: isBalanced ? _okColor : _warnColor,
                ),
                const SizedBox(width: 4),
                CustomText(
                  text: isBalanced
                      ? 'Balanced'
                      : '${exception.deviationPercent > 0 ? '+' : ''}${exception.deviationPercent.round()}% vs budget',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: isBalanced ? _okColor : _warnColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            MacroChipRow(
              protein: day.totalProtein,
              fiber: day.totalFiber,
              carbs: day.totalCarbs,
              fat: day.totalFats,
            ),
          ],
        ),
      );
    });
  }
}

class _DayTimeline extends StatelessWidget {
  final WizardDayGroup day;

  const _DayTimeline({required this.day});

  @override
  Widget build(BuildContext context) {
    final meals = day.meals.where((m) => m.items.isNotEmpty || m.supplements.isNotEmpty).toList();
    if (meals.isEmpty) {
      return const CustomText(
        text: 'No meals for this day.',
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
                    _RecipeCard(item: item),
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
  final WizardPlanItem item;

  const _RecipeCard({required this.item});

  /// The typed days[] schema's `displayText` (a formatted portion string)
  /// is never actually written by any backend endpoint yet - always falls
  /// back to the raw servingMultiplier.
  String get _portionLabel {
    if (item.displayText != null && item.displayText!.isNotEmpty) return item.displayText!;
    final m = item.servingMultiplier;
    final formatted = m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(2);
    return m == 1 ? '1 serving' : '$formatted servings';
  }

  @override
  Widget build(BuildContext context) {
    final n = item.calculatedNutrition;
    num? macro(String key) => n?[key] as num?;

    return WizardRecipeCard(
      title: item.recipeName ?? item.recipeId,
      portionLabel: _portionLabel,
      calories: item.calories?.round(),
      macros: n == null
          ? null
          : MacroChipRow(protein: macro('protein'), fiber: macro('fiber'), carbs: macro('carbs'), fat: macro('fats')),
      actions: [
        if (item.isLinkedComponent)
          const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.link, size: 14, color: WizardPalette.muted)),
        if (item.locked)
          const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock, size: 14, color: WizardPalette.muted)),
      ],
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
