import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/wizard_controller.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _cardBg = Color(0xffFEF6FB);
const _cardBorder = Color(0xffFDF2FA);

/// Step 1 (Context, ~10 seconds): a pre-filled read-only patient summary -
/// no editing here, just confirming who this plan is for before moving on.
class ContextStepView extends StatelessWidget {
  const ContextStepView({super.key});

  @override
  Widget build(BuildContext context) {
    final wizard = Get.find<WizardController>();

    return Obx(() {
      final profile = wizard.patientsController.patientProfileModel.value;
      if (profile == null || profile.basic == null) {
        return const Center(child: CircularProgressIndicator(color: Color(0xff851653)));
      }

      final basic = profile.basic!;
      final health = profile.healthSummary;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            CustomText(
              text: basic.fullName ?? 'Patient',
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: _headerColor,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                border: Border.all(color: _cardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Gender', basic.gender ?? '—'),
                  _infoRow('Date of birth', basic.dateOfBirth ?? '—'),
                  _infoRow('Weight', health?.weight != null ? '${health!.weight} kg' : '—'),
                  _infoRow('Height', health?.height != null ? '${health!.height} cm' : '—'),
                  _infoRow('Goal', health?.primaryGoal ?? '—'),
                  _infoRow('Target weight', health?.targetWeight ?? '—'),
                  _infoRow('Activity level', health?.activityLevel ?? '—'),
                  if ((health?.healthConcerns ?? []).isNotEmpty)
                    _infoRow('Health concerns', health!.healthConcerns!.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              onTap: wizard.nextStep,
              text: 'Continue',
              isOutline: false,
              buttonColor: _headerColor,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: CustomText(
              text: label,
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: _mutedColor,
            ),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
