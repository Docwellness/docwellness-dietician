import 'package:docwellnesdoc/app/modules/diet_plan_wizard/controllers/timeline_step_controller.dart'
    show requiredServingTimes;
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/finalize_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';
import '../widgets/fraction_dial.dart';
import '../widgets/swap_vs_scale_sheet.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);
const _warnColor = Color(0xffB45309);
const _okColor = Color(0xff059669);

const List<double> _weekTweakSteps = [0.75, 1.0, 1.25];

/// Step 5 (Finalize & Clever Adjustments) - see finalize_step_controller.dart
/// for why this has two sub-states (draft review, then post-finalize
/// adjustments).
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
                  text: 'Once finalized, Week Tweak, Swap vs Scale, and Exception Review become available for adjustments.',
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

class _CleverAdjustmentsView extends StatelessWidget {
  final FinalizeStepController controller;

  const _CleverAdjustmentsView({required this.controller});

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
                _WeekTweakPanel(controller: controller),
                const SizedBox(height: 20),
                _ExceptionReviewList(controller: controller),
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
              onTap: () async {
                final ok = await controller.activatePlan();
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
  }
}

/// Zone 1: [0.75x | 1.0x | 1.25x] per servingTime.
class _WeekTweakPanel extends StatelessWidget {
  final FinalizeStepController controller;

  const _WeekTweakPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'Week Tweak', fontWeight: FontWeight.w600, fontSize: 15, color: _headerColor),
          const SizedBox(height: 8),
          ...requiredServingTimes.map(
            (servingTime) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(text: servingTime, fontWeight: FontWeight.w400, fontSize: 13, color: _bodyColor),
                  ),
                  ..._weekTweakSteps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => controller.applyWeekTweak(servingTime, step),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: _primaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomText(
                            text: '${step}x',
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: _primaryColor,
                          ),
                        ),
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

/// Zone 2 + 3: days within tolerance collapse to a single "Balanced" row;
/// days outside tolerance expand into their Smart Recipe Cards.
class _ExceptionReviewList extends StatelessWidget {
  final FinalizeStepController controller;

  const _ExceptionReviewList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final exceptionsByDayGroup = {for (final e in controller.calorieExceptions) e.dayGroup: e};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(text: 'Days', fontWeight: FontWeight.w600, fontSize: 15, color: _headerColor),
          const SizedBox(height: 8),
          ...controller.weekDays.map((day) {
            final exception = exceptionsByDayGroup[day.dayGroup];
            final isBalanced = exception == null;
            return _DayCard(
              day: day,
              exception: exception,
              isBalanced: isBalanced,
              controller: controller,
            );
          }),
        ],
      );
    });
  }
}

class _DayCard extends StatefulWidget {
  final WizardDayGroup day;
  final WizardCalorieException? exception;
  final bool isBalanced;
  final FinalizeStepController controller;

  const _DayCard({required this.day, required this.exception, required this.isBalanced, required this.controller});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late bool _expanded = !widget.isBalanced;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffFDF2FA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    widget.isBalanced ? Icons.check_circle : Icons.warning_rounded,
                    size: 16,
                    color: widget.isBalanced ? _okColor : _warnColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      text: widget.isBalanced
                          ? '${widget.day.dayGroup}: Balanced'
                          : '${widget.day.dayGroup}: ${widget.exception!.deviationPercent > 0 ? '+' : ''}${widget.exception!.deviationPercent.round()}% vs budget',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: widget.isBalanced ? _bodyColor : _warnColor,
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: _mutedColor),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: widget.day.meals.expand((meal) {
                  return meal.items.map(
                    (item) => _SmartRecipeCard(
                      dayGroup: widget.day.dayGroup,
                      servingTime: meal.servingTime,
                      item: item,
                      controller: widget.controller,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Zone 3: one card per plan item - Fraction Dial + (for an over-budget
/// item) a Swap vs Scale entry point.
class _SmartRecipeCard extends StatelessWidget {
  final String dayGroup;
  final String servingTime;
  final WizardPlanItem item;
  final FinalizeStepController controller;

  const _SmartRecipeCard({
    required this.dayGroup,
    required this.servingTime,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xffFAFAFA), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: '$servingTime · ${item.recipeName ?? item.recipeId}',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: _bodyColor,
                ),
              ),
              if (item.isLinkedComponent)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.link, size: 14, color: _mutedColor),
                ),
              if (item.locked) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock, size: 14, color: _mutedColor)),
            ],
          ),
          if (item.calories != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CustomText(
                text: '${item.calories!.round()} Cal',
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: _mutedColor,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              FractionDial(
                value: item.servingMultiplier,
                onChanged: item.locked
                    ? (_) {}
                    : (v) => controller.scaleItem(item, dayGroup, servingTime, v),
              ),
              const Spacer(),
              if (!item.locked)
                InkWell(
                  onTap: () => _openSwapVsScale(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.swap_horiz, size: 18, color: _primaryColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSwapVsScale(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SwapVsScaleSheet(
        item: item,
        deviationCalories: null,
        onLoadAlternatives: (direction) => controller.getAlternatives(
          item: item,
          dayGroup: dayGroup,
          servingTime: servingTime,
          direction: direction,
        ),
        onSelectAlternative: (alt) => controller.swapItem(
          item: item,
          dayGroup: dayGroup,
          servingTime: servingTime,
          newRecipeId: alt.id,
          reason: 'Swapped via Swap vs Scale',
        ),
        onScaleInstead: () {},
      ),
    );
  }
}
