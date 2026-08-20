import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:get/get.dart';

/// Owns ONLY cross-step orchestration for the 5-Step Wizard: which step is
/// active, the patient/plan identity every step needs, and step-to-step
/// navigation - never a specific step's own UI/form state (each step has its
/// own lightweight controller for that, see e.g. targets_step_controller.dart)
/// so this doesn't grow into the same god-controller shape as
/// patients/controllers/patients_controller.dart.
///
/// Reads Get.parameters on init (patientId/dietPlanId/step, populated from
/// the URL by app_pages.dart's wizard GetPage) so a browser refresh mid-
/// wizard resumes at the right step instead of losing all context - same
/// convention already used for PatientProfileView/SelectDietSheet.
class WizardController extends GetxController {
  final String patientId;
  final String patientName;
  final String firstConsultationId;
  final String requestId;

  /// Null until Step 4 (Generation) succeeds and creates/identifies the
  /// plan being built.
  final RxnString dietPlanId = RxnString();

  /// 1-4 - which internal week this wizard run is generating. Golden's
  /// weeks-3-4 regen and Platinum's one-at-a-time cadence still resolve to
  /// a single "week" value here for Step 2/3's purposes; multi-week
  /// generation itself is handled by PatientsController.regenerateWeek's
  /// existing weekNumbers list, reused as-is (see generation_step_controller).
  final RxInt targetWeek;

  /// Which week(s) Step 4 (Generation) actually requests - a plain [targetWeek]
  /// for the common case, or e.g. [3, 4] for Golden's paired weeks-3-4
  /// regeneration (see PatientsController.regenerateWeek's weekNumbers param
  /// and utils/membershipTiers.js's tier-gated cadence on the backend).
  /// Defaults to [targetWeek] alone when not explicitly overridden.
  final List<int> weeksToGenerate;

  final RxInt currentStep;

  static const int stepCount = 5;

  final PatientsController patientsController = Get.find<PatientsController>();

  WizardController({
    required this.patientId,
    required this.patientName,
    required this.firstConsultationId,
    required this.requestId,
    String? initialDietPlanId,
    int initialWeek = 1,
    List<int>? weeksToGenerate,
    int initialStep = 1,
  }) : targetWeek = initialWeek.obs,
       weeksToGenerate = weeksToGenerate ?? [initialWeek],
       currentStep = initialStep.clamp(1, stepCount).obs {
    if (initialDietPlanId != null && initialDietPlanId.isNotEmpty) {
      dietPlanId.value = initialDietPlanId;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Context step needs the patient profile loaded - reuse
    // PatientsController's existing fetch/cache rather than duplicating it.
    if (patientsController.patientProfileModel.value?.id != patientId) {
      patientsController.getPatientProfile(patientId);
    }
  }

  void goToStep(int step) {
    if (step < 1 || step > stepCount) return;
    currentStep.value = step;
  }

  void nextStep() => goToStep(currentStep.value + 1);

  void previousStep() => goToStep(currentStep.value - 1);

  bool get isFirstStep => currentStep.value == 1;

  bool get isLastStep => currentStep.value == stepCount;
}
