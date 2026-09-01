import 'package:docwellnesdoc/app/modules/patients/utils/diet_target_calculations.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/targets_step_controller.dart';
import '../controllers/wizard_controller.dart';
import '../widgets/wizard_widgets.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff384250);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);
const _cardBorder = Color(0xffFAA7E0);

/// Step 2 (Targets, ~20 seconds): calorie-strategy cards (Gentle/Steady/
/// Accelerated/Extreme) + macro-strategy cards (Balanced/Low-Carb). Same
/// math as CreateDietPlanScreen (see diet_target_calculations.dart), styled
/// for the wizard's own step chrome.
class TargetsStepView extends StatelessWidget {
  const TargetsStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<TargetsStepController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Obx(() {
            final m = controller.bodyMetrics.value;
            if (m == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BodyMetricsCard(bmi: m.bmi, bmr: m.bmr, tdee: m.tdee),
            );
          }),
          const CustomText(
            text: 'Calories',
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: _headerColor,
          ),
          const SizedBox(height: 10),
          Obx(
            () => Column(
              children: controller.calorieTiers
                  .map(
                    (tier) => _CalorieTierCard(
                      tier: tier,
                      selected: controller.selectedCalorieTitle.value == tier.title,
                      onTap: () => controller.selectCalorieTier(tier.title),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          const CustomText(
            text: 'Macros',
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: _headerColor,
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (controller.selectedCalorieTitle.value == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CustomText(
                  text: 'Select a calorie plan first.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: _mutedColor,
                ),
              );
            }
            return Column(
              children: controller.macroOptions
                  .map(
                    (option) => _MacroOptionCard(
                      option: option,
                      selected: controller.selectedMacroTitle.value == option.title,
                      onTap: () => controller.selectMacroOption(option.title),
                    ),
                  )
                  .toList(),
            );
          }),
          const SizedBox(height: 24),
          Obx(
            () => WizardStepFooter(
              primaryLabel: 'Continue',
              onPrimary: controller.canContinue ? wizard.nextStep : null,
              primaryDisabled: !controller.canContinue,
              onSaveExit: () => Get.back(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Read-only strip above the calorie cards: the patient's BMI, BMR and
/// TDEE - the physiological baseline every calorie budget below is derived
/// from. Not selectable, so it's deliberately styled apart from the tier
/// cards (no radio, filled tint, hairline-divided columns).
class _BodyMetricsCard extends StatelessWidget {
  final double bmi;
  final double bmr;
  final double tdee;

  const _BodyMetricsCard({required this.bmi, required this.bmr, required this.tdee});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        border: Border.all(color: _cardBorder, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _metric(
                    'BMI',
                    bmi > 0 ? bmi.toStringAsFixed(1) : '—',
                    bmiCategory(bmi),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: _cardBorder,
                  indent: 6,
                  endIndent: 6,
                ),
                Expanded(child: _metric('BMR', bmr.round().toString(), 'kcal/day')),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: _cardBorder,
                  indent: 6,
                  endIndent: 6,
                ),
                Expanded(child: _metric('TDEE', tdee.round().toString(), 'kcal/day')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: CustomText(
              text: 'Each calorie plan below is TDEE minus its daily deficit.',
              fontWeight: FontWeight.w400,
              fontSize: 11.5,
              color: _mutedColor,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, String sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          text: label,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: _mutedColor,
        ),
        const SizedBox(height: 3),
        CustomText(
          text: value,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: _headerColor,
        ),
        const SizedBox(height: 2),
        CustomText(
          text: sub,
          fontWeight: FontWeight.w400,
          fontSize: 10.5,
          color: _mutedColor,
        ),
      ],
    );
  }
}

class _CalorieTierCard extends StatelessWidget {
  final CalorieTierResult tier;
  final bool selected;
  final VoidCallback onTap;

  const _CalorieTierCard({required this.tier, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffFEF6FB) : Colors.white,
            border: Border.all(color: selected ? _primaryColor : _cardBorder, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: tier.title,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _bodyColor,
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? _primaryColor : _mutedColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomText(
                text: tier.description,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: _mutedColor,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _statChip('Budget', '${tier.calorieBudget.round()} Cal'),
                  _statChip('Deficit', '${tier.deficit} Cal'),
                  _statChip('Weekly change', '${tier.weeklyChangeKg.toStringAsFixed(2)} kg'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: _mutedColor, fontSize: 12)),
          TextSpan(
            text: value,
            style: const TextStyle(color: _bodyColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MacroOptionCard extends StatelessWidget {
  final MacroOptionResult option;
  final bool selected;
  final VoidCallback onTap;

  const _MacroOptionCard({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffFEF6FB) : Colors.white,
            border: Border.all(color: selected ? _primaryColor : _cardBorder, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: option.title,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _bodyColor,
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? _primaryColor : _mutedColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CustomText(
                text: option.description,
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: _mutedColor,
              ),
              const SizedBox(height: 8),
              CustomText(
                text: 'Fat ${option.fatPercent}% (${option.fatGrams}g) · '
                    'Carbs ${option.carbsPercent}% (${option.carbsGrams}g) · '
                    'Protein ${option.proteinPercent}% (${option.proteinGrams}g)',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: _bodyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
