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
          Obx(() {
            final step = wizard.currentStep.value;
            // Reopened-plan review (step 5): no back button - the way out is
            // the "Done" footer. On Refine (reached from the menu) the back
            // arrow returns to that review, not down the linear step order.
            final onReopenReview = wizard.reopenedPlanView && step == WizardController.reopenedReviewStep;
            final onReopenRefine = wizard.reopenedPlanView && step == 3;
            return Row(
              children: [
                if (onReopenReview)
                  const SizedBox(width: 8)
                else
                  IconButton(
                    onPressed: onReopenRefine
                        ? () => wizard.goToStep(WizardController.reopenedReviewStep)
                        : (wizard.isFirstStep ? () => Get.back() : wizard.previousStep),
                    icon: Icon(
                      wizard.isFirstStep && !onReopenRefine ? Icons.close : Icons.arrow_back,
                      color: _headerColor,
                    ),
                  ),
                Expanded(
                  child: CustomText(
                    text: onReopenReview
                        ? 'Diet Plan - ${wizard.patientName}'
                        : 'Create Diet Plan - ${wizard.patientName}',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: _headerColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onReopenReview)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: _headerColor),
                    onSelected: (value) {
                      if (value == 'refine') {
                        wizard.startRefine();
                      } else if (value == 'regenerate') {
                        _confirmRegenerate(context, wizard);
                      }
                    },
                    // "Refine Plan" jumps to step 3, which is only a
                    // distinct Refine Portions step in the v4.0 new-plan
                    // order (isNewPlanFlow) - the days-array regeneration
                    // order's step 3 is Timeline, so offering it there would
                    // silently land the dietician on the wrong step. Days-
                    // array's reopened review (e.g. a currently-ongoing,
                    // already-finalized week tapped from the patient
                    // profile) only offers Regenerate Plan, which correctly
                    // maps to step 1 (Context) either way.
                    itemBuilder: (_) => [
                      if (wizard.isNewPlanFlow)
                        const PopupMenuItem(value: 'refine', child: Text('Refine Plan')),
                      const PopupMenuItem(value: 'regenerate', child: Text('Regenerate Plan')),
                    ],
                  ),
              ],
            );
          }),
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

  /// "Regenerate Plan" from the review menu: confirm (it discards every
  /// current recipe and any hand-tuned portions), then hand off to the
  /// wizard which sends the dietician to Targets and re-runs generation.
  Future<void> _confirmRegenerate(BuildContext context, WizardController wizard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const CustomText(text: 'Regenerate this plan?', fontWeight: FontWeight.w600, fontSize: 16, color: _headerColor),
        content: const CustomText(
          text: 'The current recipes and any portion edits are replaced with a fresh AI selection. You can adjust the calorie and macro targets first. This cannot be undone.',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: Color(0xff1F2A37),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const CustomText(text: 'Cancel', fontWeight: FontWeight.w500, fontSize: 13, color: _mutedColor),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const CustomText(text: 'Regenerate', fontWeight: FontWeight.w600, fontSize: 13, color: _headerColor),
          ),
        ],
      ),
    );
    if (confirmed == true) wizard.startRegenerate();
  }
}
