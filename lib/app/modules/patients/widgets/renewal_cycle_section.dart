import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/bindings/wizard_binding.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/controllers/wizard_controller.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/views/wizard_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shown on the patient profile under "Weekly Diet Plans" while a renewal
/// is in progress (`status.renewalPending`). The current cycle's cards
/// above stay untouched - this is the *next* cycle the dietician has to
/// build. Weeks display as "Week 5-8" (`PendingCycle.displayWeek`).
///
/// Before the first generation `pendingCycle` is null - just the header +
/// a "Create Diet Plan" button that opens the wizard fresh (the backend
/// treats a generate call for a patient with a live Active plan as "start
/// the next cycle"). Once building has started, the 4 week cards reflect
/// generated / finalized state and the button becomes "Resume".
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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

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

  Future<void> _openWizard(BuildContext context) async {
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
          Row(
            children: [
              const Icon(Icons.autorenew_rounded,
                  size: 18, color: Color(0xff851653)),
              const SizedBox(width: 6),
              const CustomText(
                text: 'Next cycle',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xff530630),
              ),
              const SizedBox(width: 8),
              if (status.pendingMembershipPlan != null &&
                  status.pendingMembershipPlan!.isNotEmpty)
                Flexible(
                  child: CustomText(
                    text: 'requested: ${status.pendingMembershipPlan}',
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: const Color(0xff6C737F),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (pc != null) ...[
            SizedBox(
              height: 118,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final week = index + 1;
                  final displayWeek = pc.displayWeek(week);
                  final isFinalized = pc.finalizedWeekNumbers.contains(week);
                  final isGenerated =
                      pc.generatedWeekNumbers.contains(week) && !isFinalized;
                  final sched = pc.scheduleFor(week);
                  final range = (sched?.startDate != null && sched?.endDate != null)
                      ? '${_shortDate(sched!.startDate!)} - ${_shortDate(sched.endDate!)}'
                      : null;
                  final hasContent = isFinalized || isGenerated;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openWizard(context),
                      child: Container(
                        width: 118,
                        decoration: BoxDecoration(
                          color: hasContent
                              ? const Color(0xffFEF6FB)
                              : const Color(0xffF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasContent
                                ? const Color(0xff851653)
                                : const Color(0xffE5E7EB),
                            width: hasContent ? 1.4 : 1,
                          ),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isFinalized
                                  ? Icons.check_circle_rounded
                                  : isGenerated
                                      ? Icons.restaurant_menu_rounded
                                      : Icons.add_circle_outline_rounded,
                              size: 22,
                              color: hasContent
                                  ? const Color(0xff851653)
                                  : const Color(0xff9DA4AE),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Week $displayWeek',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFinalized
                                  ? 'Finalized'
                                  : isGenerated
                                      ? 'Pick meals'
                                      : 'Not started',
                              style: TextStyle(
                                fontSize: 10,
                                color: hasContent
                                    ? const Color(0xff851653)
                                    : const Color(0xff9DA4AE),
                              ),
                            ),
                            if (range != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                range,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Color(0xff9DA4AE),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
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
              onTap: () => _openWizard(context),
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
