import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/generation_step_controller.dart';
import '../controllers/wizard_controller.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

const Map<GenerationPhase, String> _phaseLabels = {
  GenerationPhase.generatingMeals: 'Generating meals...',
  GenerationPhase.calculatingPortions: 'Calculating portions...',
  GenerationPhase.balancingCalories: 'Balancing calories...',
};

/// Step 4 (Generation): triggers the actual backend call and shows a
/// staged progress indicator while it's in flight - see
/// generation_step_controller.dart for why these phases are UI-staged
/// rather than driven by real backend progress events (the request is a
/// single synchronous call).
class GenerationStepView extends StatefulWidget {
  const GenerationStepView({super.key});

  @override
  State<GenerationStepView> createState() => _GenerationStepViewState();
}

class _GenerationStepViewState extends State<GenerationStepView> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<GenerationStepController>();
    if (controller.phase.value == GenerationPhase.idle) {
      controller.generate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();
    final controller = Get.find<GenerationStepController>();

    return Obx(() {
      final phase = controller.phase.value;

      if (phase == GenerationPhase.failed) {
        return _CenteredMessage(
          icon: Icons.error_outline,
          iconColor: const Color(0xffDC2626),
          title: 'Generation failed',
          message: controller.errorMessage.value ?? 'Please try again.',
          actionLabel: 'Retry',
          onAction: controller.generate,
        );
      }

      if (phase == GenerationPhase.done) {
        return _CenteredMessage(
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xff059669),
          title: 'Plan generated',
          message: controller.supplementFlushFailures.value > 0
              ? 'The week is ready to review. ${controller.supplementFlushFailures.value} supplement(s) could not be saved - you can re-add them from the timeline.'
              : 'The week is ready to review.',
          actionLabel: 'Review & Finalize',
          onAction: wizard.nextStep,
        );
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 20),
            CustomText(
              text: _phaseLabels[phase] ?? 'Working...',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: _headerColor,
            ),
            const SizedBox(height: 8),
            const CustomText(
              text: 'This usually takes a few seconds.',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: _mutedColor,
            ),
          ],
        ),
      );
    });
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            CustomText(text: title, fontWeight: FontWeight.w600, fontSize: 18, color: _bodyColor),
            const SizedBox(height: 8),
            CustomText(
              text: message,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: _mutedColor,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              onTap: onAction,
              text: actionLabel,
              isOutline: false,
              buttonColor: _headerColor,
            ),
          ],
        ),
      ),
    );
  }
}
