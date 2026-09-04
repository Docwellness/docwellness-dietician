import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/finalize_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../models/wizard_week_models.dart';

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
                _ExceptionReviewList(controller: controller),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  const _DayCard({required this.day, required this.exception, required this.isBalanced});

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
                      servingTime: meal.servingTime,
                      item: item,
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

/// Zone 3: one read-only card per plan item - name, calories, lock/link
/// status. No adjustment controls - Week Tweak/Swap vs Scale were removed
/// as part of v4.0's hard cutover (see this file's header comment); a
/// days-array plan's already-Finalized week can only be viewed here now.
class _SmartRecipeCard extends StatelessWidget {
  final String servingTime;
  final WizardPlanItem item;

  const _SmartRecipeCard({
    required this.servingTime,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xffFAFAFA), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: '$servingTime · ${item.recipeName ?? item.recipeId}',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: _bodyColor,
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
              ],
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
    );
  }
}
