import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/day_group_label.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/timeline_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../widgets/supplement_picker_sheet.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);
const _supplementBg = Color(0xffF3E8FF);
const _supplementFg = Color(0xff6D28D9);

/// Step 3 (Timeline Builder): the plan's fixed 7-slot meal timeline (shown
/// per day-group, since Monday/Tuesday/Wednesday/Thursday can each carry
/// their own supplement schedule - see dayGroups.js's 4-group repeat
/// model), with "+ Add Supplement" injection per slot. Meal-slot
/// enable/disable toggles from the original spec are intentionally not
/// included here - there is no backend concept of skipping a required
/// slot during generation (services/recipeSelectionEngine.js always fills
/// every REQUIRED_SERVING_TIMES entry), so a toggle here would not
/// actually do anything.
class TimelineStepView extends StatelessWidget {
  const TimelineStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<TimelineStepController>();

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
                  text: 'Timeline & Supplements',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: _headerColor,
                ),
                const SizedBox(height: 4),
                const CustomText(
                  text: 'Attach any supplements to specific meal slots before generating.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: _mutedColor,
                ),
                const SizedBox(height: 16),
                ...dayGroups.map((dayGroup) => _DayGroupSection(dayGroup: dayGroup, controller: controller)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(
            onTap: () async {
              // v4.0 new-plan flow: Timeline now runs AFTER Generate (see
              // wizard_controller.dart's isNewPlanFlow doc comment), so
              // dietPlanId already exists - flush staged supplements to the
              // real endpoint right away instead of waiting for
              // GenerationStepController (which already ran, earlier).
              if (wizard.isNewPlanFlow && controller.stagedSupplements.isNotEmpty) {
                final dietPlanId = wizard.dietPlanId.value;
                if (dietPlanId != null && dietPlanId.isNotEmpty) {
                  await controller.flushToBackend(patientId: wizard.patientId, dietPlanId: dietPlanId, week: wizard.targetWeek.value);
                }
              }
              wizard.nextStep();
            },
            text: 'Continue',
            isOutline: false,
            buttonColor: _headerColor,
          ),
        ),
      ],
    );
  }
}

class _DayGroupSection extends StatelessWidget {
  final String dayGroup;
  final TimelineStepController controller;

  const _DayGroupSection({required this.dayGroup, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffFDF2FA)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(text: dayGroupLabel(dayGroup), fontWeight: FontWeight.w600, fontSize: 15, color: _bodyColor),
            const SizedBox(height: 8),
            ...requiredServingTimes.map(
              (servingTime) => _SlotRow(dayGroup: dayGroup, servingTime: servingTime, controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String dayGroup;
  final String servingTime;
  final TimelineStepController controller;

  const _SlotRow({required this.dayGroup, required this.servingTime, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final supplementsForSlot = controller.stagedSupplements
          .where((s) => s.dayGroup == dayGroup && s.servingTime == servingTime)
          .toList();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: servingTime,
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: _bodyColor,
                  ),
                ),
                InkWell(
                  onTap: () => _openPicker(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, size: 16, color: _primaryColor),
                        SizedBox(width: 4),
                        CustomText(
                          text: 'Add Supplement',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: _primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (supplementsForSlot.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: supplementsForSlot
                      .map((s) => _SupplementChip(supplement: s, controller: controller))
                      .toList(),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SupplementPickerSheet(
        dayGroup: dayGroup,
        servingTime: servingTime,
        availableSupplements: controller.availableSupplements,
        onInject: controller.addSupplement,
      ),
    );
  }
}

class _SupplementChip extends StatelessWidget {
  final StagedSupplement supplement;
  final TimelineStepController controller;

  const _SupplementChip({required this.supplement, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _supplementBg, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.medication_liquid, size: 13, color: _supplementFg),
          const SizedBox(width: 4),
          CustomText(
            text: supplement.supplementName,
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: _supplementFg,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => controller.removeSupplement(supplement),
            child: const Icon(Icons.close, size: 13, color: _supplementFg),
          ),
        ],
      ),
    );
  }
}
