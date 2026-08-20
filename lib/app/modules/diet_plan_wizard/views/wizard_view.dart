import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/wizard_controller.dart';
import 'context_step_view.dart';
import 'finalize_step_view.dart';
import 'generation_step_view.dart';
import 'plan_item_finalize_step_view.dart';
import 'targets_step_view.dart';
import 'timeline_step_view.dart';

const _primaryColor = Color(0xff851653);
const _headerColor = Color(0xff530630);
const _mutedColor = Color(0xff9DA4AE);

const List<String> _stepLabels = [
  'Context',
  'Targets',
  'Timeline',
  'Generate',
  'Finalize',
];

/// Shell for the 5-Step Wizard - a step-progress header plus whichever
/// step's view is currently active (WizardController.currentStep). Each
/// step view is self-contained and reads its own lightweight controller
/// (see wizard_binding.dart) rather than this shell owning any step's state.
class WizardView extends StatelessWidget {
  const WizardView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(wizard: wizard),
            Expanded(
              child: Obx(() {
                switch (wizard.currentStep.value) {
                  case 1:
                    return const ContextStepView();
                  case 2:
                    return const TargetsStepView();
                  case 3:
                    return const TimelineStepView();
                  case 4:
                    return const GenerationStepView();
                  case 5:
                    // v4.0: a plan-item plan gets the Ingredient-Editor-based
                    // Refine Portions / detailed Finalize view instead of
                    // Week Tweak/Fraction Dial/Swap-vs-Scale - see
                    // plan_item_finalize_step_controller.dart. dataModel is
                    // only known once Step 4 (Generation) has created the
                    // plan, so this stays FinalizeStepView (days-array,
                    // unchanged) until then.
                    return wizard.dataModel.value == 'plan-item'
                        ? const PlanItemFinalizeStepView()
                        : const FinalizeStepView();
                  default:
                    return const ContextStepView();
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  final WizardController wizard;

  const _WizardHeader({required this.wizard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(
                () => IconButton(
                  onPressed: wizard.isFirstStep
                      ? () => Get.back()
                      : wizard.previousStep,
                  icon: Icon(
                    wizard.isFirstStep ? Icons.close : Icons.arrow_back,
                    color: _headerColor,
                  ),
                ),
              ),
              Expanded(
                child: CustomText(
                  text: 'Create Diet Plan - ${wizard.patientName}',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: _headerColor,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: List.generate(WizardController.stepCount, (index) {
                final step = index + 1;
                final isActive = step == wizard.currentStep.value;
                final isDone = step < wizard.currentStep.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isActive || isDone ? _primaryColor : _mutedColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: _stepLabels[index],
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 10,
                          color: isActive ? _primaryColor : _mutedColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
