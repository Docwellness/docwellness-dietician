import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/wizard_controller.dart';
import 'context_step_view.dart';
import 'finalize_step_view.dart';
import 'generation_step_view.dart';
import 'plan_item_finalize_step_view.dart';
import 'refine_portions_step_view.dart';
import 'targets_step_view.dart';
import 'timeline_step_view.dart';

const _primaryColor = Color(0xff851653);
const _headerColor = Color(0xff530630);
const _mutedColor = Color(0xff9DA4AE);

// Existing-plan regeneration (days-array only - see
// WizardController.isNewPlanFlow's doc comment).
const List<String> _regenerationStepLabels = [
  'Context',
  'Targets',
  'Timeline',
  'Generate',
  'Finalize',
];

// v4.0: a brand-new plan, literal spec order - Targets -> Generate ->
// Refine Portions -> Timeline -> Finalize, no separate Context step.
const List<String> _newPlanStepLabels = [
  'Targets',
  'Generate',
  'Refine',
  'Timeline',
  'Finalize',
];

/// Shell for the 5-Step Wizard - a step-progress header plus whichever
/// step's view is currently active (WizardController.currentStep). Each
/// step view is self-contained and reads its own lightweight controller
/// (see wizard_binding.dart) rather than this shell owning any step's state.
///
/// The step SEQUENCE itself is chosen by wizard.isNewPlanFlow, not
/// dataModel - see that field's doc comment for why (dataModel isn't known
/// until Step 2/Generation has already run, which is too late to decide
/// what Step 1 should even be).
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
                if (wizard.isNewPlanFlow) {
                  switch (wizard.currentStep.value) {
                    case 1:
                      return const TargetsStepView();
                    case 2:
                      return const GenerationStepView();
                    case 3:
                      return const RefinePortionsStepView();
                    case 4:
                      return const TimelineStepView();
                    case 5:
                      return const PlanItemFinalizeStepView();
                    default:
                      return const TargetsStepView();
                  }
                }
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
                    return const FinalizeStepView();
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
          Obx(() {
            final labels = wizard.isNewPlanFlow ? _newPlanStepLabels : _regenerationStepLabels;
            return Row(
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
                          text: labels[index],
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 10,
                          color: isActive ? _primaryColor : _mutedColor,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
