import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/bindings/wizard_binding.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/controllers/wizard_controller.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/views/wizard_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The button that builds / resumes the pending renewal cycle, shown on the
/// patient profile just under the Weekly Diet Plans row while a renewal is
/// in progress (`status.renewalPending`). The next cycle's week cards live
/// in that row itself (continuing after the current cycle's Week 4) - this
/// is only the entry point.
///
/// Before the first generation `pendingCycle` is null: a short note + a
/// "Create Diet Plan" button that opens the wizard fresh (the backend
/// treats a generate call for a patient who already has a live Active plan
/// as "start the next cycle"). Once building has started the button becomes
/// "Resume Diet Plan".
class RenewalCycleSection extends StatelessWidget {
  final Status status;
  final PendingCycle? pendingCycle;
  final String patientId;
  final String patientName;

  /// Called after the wizard screen closes so the profile can refetch.
  final Future<void> Function() onWizardClosed;

  const RenewalCycleSection({
    super.key,
    required this.status,
    required this.pendingCycle,
    required this.patientId,
    required this.patientName,
    required this.onWizardClosed,
  });

  int _resumeStep(String? workflowStatus) {
    switch (workflowStatus) {
      case 'targets_set':
        return 2;
      case 'menu_generated':
        return 3;
      case 'portions_refined':
      case 'timeline_defined':
        return 4;
      case 'finalized':
        return 5;
      default:
        return 1;
    }
  }

  Future<void> _openWizard() async {
    final pc = pendingCycle;
    final resuming = pc != null && pc.status == 'Draft' && pc.dietPlanId != null;

    final wizardController = WizardController(
      patientId: patientId,
      patientName: patientName.split(' ').first,
      firstConsultationId: status.firstConsultationId ?? '',
      requestId: status.requestId ?? '',
      // Resume the in-progress build; otherwise null so the backend starts
      // the next cycle (it keys "new cycle" off the patient already having
      // a live Active plan, see createAndGenerateDietPlan).
      initialDietPlanId: resuming ? pc.dietPlanId : null,
      initialDataModel: resuming ? pc.dataModel : null,
      resumeInPlace: resuming,
      initialStep: resuming ? _resumeStep(pc.workflowStatus) : 1,
    );
    await Get.to(
      () => const WizardView(),
      binding: WizardBinding(wizardController),
    );
    await onWizardClosed();
  }

  @override
  Widget build(BuildContext context) {
    final pc = pendingCycle;
    final canBuild = status.patientConsented == true &&
        status.firstConsultationId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pc == null) ...[
            const CustomText(
              text:
                  'This patient requested a renewal. Build their next cycle '
                  'here - the current plan keeps running until you activate '
                  'the new one.',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xff6C737F),
              height: 1.4,
            ),
            const SizedBox(height: 10),
          ],
          if (canBuild)
            CustomButton(
              onTap: _openWizard,
              text: (pc != null && pc.status == 'Draft')
                  ? 'Resume Diet Plan'
                  : 'Create Diet Plan',
              isOutline: false,
              fontSize: 14,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffFAA7E0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      color: Color(0xff851653), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      text:
                          'Waiting for the patient to review their consultation '
                          'and submit consent before the next plan can be built.',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xff851653),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
