import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/plan_item_finalize_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

/// Step 5 (Finalize), v4.0 mode - see plan_item_finalize_step_controller.dart
/// for why this is now always the read-only detail view (Refine Portions,
/// formerly a pre-finalize sub-state here, is its own Step 3 now).
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
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const CustomText(text: 'Review & Finalize', fontWeight: FontWeight.w500, fontSize: 20, color: _headerColor),
                  const SizedBox(height: 4),
                  const CustomText(
                    text: 'Exactly what will be prescribed - review before confirming.',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: _mutedColor,
                  ),
                  const SizedBox(height: 12),
                  if (controller.targetCalories != null)
                    ...controller.dayCalorieChecks.map(
                      (check) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              check.withinTolerance ? Icons.check_circle : Icons.error,
                              size: 16,
                              color: check.withinTolerance ? const Color(0xff12B76A) : const Color(0xffDC2626),
                            ),
                            const SizedBox(width: 6),
                            CustomText(
                              text:
                                  '${check.dayGroup}: ${check.totalCalories.round()} cal (target ${controller.targetCalories!.round()} cal)',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: check.withinTolerance ? _mutedColor : const Color(0xffDC2626),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (controller.targetCalories != null && !controller.canActivate)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CustomText(
                        text: 'Every day must be within ±5% of the calorie target before this plan can be activated.',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xffDC2626),
                      ),
                    ),
                  ...controller.weekDays.map((day) => _FinalizedDayCard(day: day)),
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
                isLoading: controller.activating.value,
                isDisabled: !controller.canActivate,
                onTap: () async {
                  final ok = await controller.finalizeAndActivate();
                  if (ok) Get.back();
                },
                text: 'Confirm & Activate',
                isOutline: false,
                buttonColor: _headerColor,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FinalizedDayCard extends StatelessWidget {
  final WizardDayGroupV2 day;

  const _FinalizedDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xffFDF2FA)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: day.dayGroup, fontWeight: FontWeight.w600, fontSize: 14, color: _bodyColor),
          const SizedBox(height: 6),
          ...day.meals.where((m) => m.items.isNotEmpty || m.supplements.isNotEmpty).map(
            (meal) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(text: meal.servingTime, fontWeight: FontWeight.w500, fontSize: 12, color: _primaryColor),
                  ...meal.items.map((item) => _FinalizedItemDetail(item: item)),
                  ...meal.supplements.map(
                    (supplement) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.medication, size: 14, color: _mutedColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: CustomText(
                              text: '${supplement.supplementName ?? 'Supplement'}${supplement.dosage != null ? ' · ${supplement.dosage}' : ''} (${supplement.timingAnchor})',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: _bodyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalizedItemDetail extends StatelessWidget {
  final WizardPlanItemV2 item;

  const _FinalizedItemDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final version = item.recipeVersion;
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: item.recipeName, fontWeight: FontWeight.w500, fontSize: 13, color: _bodyColor),
          if (version != null && version.ingredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomText(
                text: version.ingredients
                    .map((i) => '${i.foodItemName ?? '?'} ${i.rawQuantity.toStringAsFixed(i.rawQuantity % 1 == 0 ? 0 : 1)}${i.unit}')
                    .join(', '),
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: _mutedColor,
              ),
            ),
          if (version != null && version.steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomText(
                text: version.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('  '),
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: _mutedColor,
              ),
            ),
        ],
      ),
    );
  }
}
