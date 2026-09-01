import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:get/get.dart';

import '../services/diet_plan_wizard_service.dart';

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

  /// v4.0: 'plan-item' | 'days-array' | null (unknown until dietPlanId is
  /// set - see generation_step_controller.dart). Gates which of the two
  /// completely different Step 5 experiences (Ingredient Editor vs Fraction
  /// Dial/Week Tweak/Swap-vs-Scale) wizard_view.dart shows, and which
  /// backend endpoints Step 3's supplement flush targets.
  final RxnString dataModel = RxnString();

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

  /// True only for a genuinely brand-new plan (no initialDietPlanId at
  /// construction - see patient_profile_view.dart's two call sites: the
  /// "Create Diet Plan" button passes none, "regenerate week N" always
  /// passes the existing plan's id). Decided once, at construction, since
  /// dataModel itself isn't known until Step 2/Generation actually runs -
  /// this is what wizard_view.dart routes the step SEQUENCE on (not
  /// dataModel), because the sequence has to be picked before Generation
  /// has had a chance to tell us which data model this plan ended up on.
  ///
  /// New-plan flow uses the v4.0-spec-literal order (Targets -> Generate ->
  /// Refine Portions -> Timeline -> Finalize, dropping Context entirely -
  /// see wizard_view.dart) since every new plan on this deployment is
  /// 'plan-item' right now (DIET_PLAN_DATA_MODEL is globally set). Existing-
  /// plan regeneration keeps the original order (Context/Targets/Timeline/
  /// Generate/Finalize) untouched - that path is days-array-only per
  /// generation_step_controller.dart's own scoping note (no generate-week
  /// equivalent exists yet for plan-item plans), so it was never a
  /// candidate for reordering in the first place.
  final bool isNewPlanFlow;

  final PatientsController patientsController = Get.find<PatientsController>();
  final DietPlanWizardService _wizardService = DietPlanWizardService();

  // ── Shared week plan-items cache ─────────────────────────────────────
  // getWeekPlanItems is a heavy multi-collection join (DayPlan -> MealSlot
  // -> PlanItem -> RecipeVersion -> FoodItem, plus supplements). Steps 2/3/5
  // each used to fetch it independently on entry - so moving Generate ->
  // Refine -> Finalize re-paid the full cost three times even when nothing
  // had changed. This memoizes the last successful response for the current
  // (dietPlanId, week); any step that MUTATES plan items or supplements
  // passes forceRefresh:true (which also repopulates the cache) or calls
  // invalidateWeekPlanItems(). Concurrent identical calls share one request.
  Map<String, dynamic>? _weekPlanItemsCache;
  String? _weekPlanItemsCacheKey;
  Future<Map<String, dynamic>?>? _weekPlanItemsInFlight;

  String get _weekKey => '${dietPlanId.value ?? ''}|${targetWeek.value}';

  /// Shared getWeekPlanItems - returns the cached response for the current
  /// plan/week unless [forceRefresh]. A null/failed response is never
  /// cached. Safe to call from several controllers at once: an in-flight
  /// request is reused rather than duplicated.
  Future<Map<String, dynamic>?> loadWeekPlanItems({bool forceRefresh = false}) async {
    final planId = dietPlanId.value ?? '';
    if (planId.isEmpty) return null;

    if (!forceRefresh && _weekPlanItemsCache != null && _weekPlanItemsCacheKey == _weekKey) {
      return _weekPlanItemsCache;
    }
    if (_weekPlanItemsInFlight != null) return _weekPlanItemsInFlight;

    final future = _fetchWeekPlanItems(planId, targetWeek.value);
    _weekPlanItemsInFlight = future;
    try {
      return await future;
    } finally {
      _weekPlanItemsInFlight = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchWeekPlanItems(String planId, int week) async {
    final response = await _wizardService.getWeekPlanItems(
      patientId: patientId,
      dietPlanId: planId,
      week: week,
    );
    if (response is Map<String, dynamic> && response['success'] == true) {
      _weekPlanItemsCache = response;
      _weekPlanItemsCacheKey = '$planId|$week';
      return response;
    }
    return response is Map<String, dynamic> ? response : null;
  }

  /// Drop the cached week plan-items so the next [loadWeekPlanItems] refetches.
  /// Call after any add / remove / swap / ingredient edit / auto-balance /
  /// supplement change that a later step needs to see.
  void invalidateWeekPlanItems() {
    _weekPlanItemsCache = null;
    _weekPlanItemsCacheKey = null;
  }

  /// The plan's Step-1 calorie budget, read from the last getWeekPlanItems
  /// response. The authoritative fallback for Refine / Finalize when the
  /// wizard was resumed straight to a later step and Targets never ran this
  /// session to populate patientsController.selectedCalorieStrategy.
  double? get planCalorieTarget {
    final data = _weekPlanItemsCache?['data'];
    if (data is! Map) return null;
    return (data['calorieTarget'] as num?)?.toDouble();
  }

  WizardController({
    required this.patientId,
    required this.patientName,
    required this.firstConsultationId,
    required this.requestId,
    String? initialDietPlanId,
    int initialWeek = 1,
    List<int>? weeksToGenerate,
    int initialStep = 1,
    // Resume an unfinished Draft in place: keep the new-plan 5-step order
    // (Targets -> Generate -> Refine -> Timeline -> Finalize) even though a
    // dietPlanId is already known - unlike the days-array regeneration flow,
    // which passing initialDietPlanId alone would otherwise switch to. The
    // caller also supplies initialStep (from the plan's workflowStatus) and
    // initialDataModel so a resume straight to Timeline still flushes
    // supplements to the right endpoint.
    bool resumeInPlace = false,
    String? initialDataModel,
  }) : targetWeek = initialWeek.obs,
       weeksToGenerate = weeksToGenerate ?? [initialWeek],
       currentStep = initialStep.clamp(1, stepCount).obs,
       isNewPlanFlow = resumeInPlace || initialDietPlanId == null || initialDietPlanId.isEmpty {
    if (initialDietPlanId != null && initialDietPlanId.isNotEmpty) {
      dietPlanId.value = initialDietPlanId;
    }
    if (initialDataModel != null && initialDataModel.isNotEmpty) {
      dataModel.value = initialDataModel;
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
    // Warm the whole recipe catalog in ONE request now, at the very start
    // of the wizard - long before Step 2's Add / Swap pickers need it. Was
    // previously a per-serving-time GET fired lazily on the Generate screen
    // (up to 7, plus one per picker open). Fire-and-forget; every later
    // listRecipes(servingTime:) call reads from this instead of the network.
    RecipeService().prefetchWizardCatalog();
  }

  @override
  void onClose() {
    // The catalog is wizard-session-scoped - don't let it leak into an
    // unrelated later screen's listRecipes calls.
    RecipeService.clearWizardCatalog();
    super.onClose();
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
