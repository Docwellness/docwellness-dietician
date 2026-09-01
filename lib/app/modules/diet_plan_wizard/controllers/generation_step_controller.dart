import 'dart:async';

import 'package:get/get.dart';

import '../services/diet_plan_wizard_service.dart';
import 'timeline_step_controller.dart';
import 'wizard_controller.dart';

enum GenerationPhase { idle, generatingMeals, calculatingPortions, balancingCalories, done, failed }

/// Step 4 (Generation): triggers the actual diet-plan generation - reuses
/// PatientsController.generateDietPlan/regenerateWeek unchanged (the
/// existing, tier-gated, battle-tested orchestration - see that
/// controller's doc comments) rather than re-deriving membership-tier
/// cadence rules here. This step's own job is just the staged-progress UI
/// and, once a dietPlanId exists, flushing Step 3's staged supplements to it.
///
/// v4.0: for a brand-new plan whose dataModel comes back 'plan-item',
/// generateDietPlan only creates the (empty, workflowStatus:'targets_set')
/// DietPlan - this step ALSO calls the new generate-menu endpoint
/// immediately after, so "Generation" still means "meals exist" for both
/// data models by the time this step reports done. Resuming/regenerating an
/// EXISTING plan-item plan (the regenerateWeek branch below) isn't wired up
/// yet - the backend has no generate-week equivalent for plan-item plans -
/// so that path stays days-array-only for now.
class GenerationStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();
  final DietPlanWizardService wizardService = DietPlanWizardService();

  final Rx<GenerationPhase> phase = GenerationPhase.idle.obs;
  final RxnString errorMessage = RxnString();
  final RxInt supplementFlushFailures = 0.obs;

  Future<void> generate({double? currentWeight, DateTime? startDate}) async {
    phase.value = GenerationPhase.generatingMeals;
    errorMessage.value = null;

    final existingDietPlanId = wizard.dietPlanId.value;
    final isNewPlan = existingDietPlanId == null || existingDietPlanId.isEmpty;
    // Resuming a new-plan-flow Draft that got as far as Targets (a
    // dietPlanId exists, but generate-menu never ran) - the plan is already
    // created, it just needs its menu, so neither generateDietPlan nor the
    // days-array regenerateWeek applies.
    final isResumeBeforeMenu = !isNewPlan && wizard.isNewPlanFlow;

    // Defensive guard, not the normal path: within one uninterrupted wizard
    // session this controller's own onInit-gated call site already only
    // calls generate() once. But a freshly constructed controller reaching
    // this screen with a dietPlanId that already has generated items (e.g.
    // resuming) must not silently re-run the whole AI generation pipeline -
    // only the explicit, confirmed "Regenerate" action (regenerateMenu
    // below) may do that.
    if (!isNewPlan) {
      final existing = await wizard
          .loadWeekPlanItems()
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      // Couldn't reach the server to check - do NOT fall through to
      // generation (that would double-generate an already-filled plan on a
      // resume). Fail with a retry instead.
      if (existing == null) {
        errorMessage.value = 'Couldn\'t load the existing plan - check your connection and retry.';
        phase.value = GenerationPhase.failed;
        return;
      }
      final days = (existing['data']?['days'] as List?) ?? const [];
      final alreadyHasItems = days.any((day) => ((day as Map)['meals'] as List? ?? []).any((meal) => ((meal as Map)['items'] as List? ?? []).isNotEmpty));
      if (alreadyHasItems) {
        wizard.dataModel.value = 'plan-item';
        phase.value = GenerationPhase.done;
        return;
      }
    }

    // Fake-staged progress - the backend call itself is a single request/
    // response (no real progress events), but the generation pipeline
    // (recipe selection -> nutrition calc -> calorie balancing, whichever
    // engine is active) genuinely does those phases internally, so this
    // still communicates real work happening rather than a bare spinner.
    unawaited(_advancePhaseAfter(GenerationPhase.calculatingPortions, const Duration(milliseconds: 900)));
    unawaited(_advancePhaseAfter(GenerationPhase.balancingCalories, const Duration(milliseconds: 1800)));

    String? resultDietPlanId;
    bool success;
    if (isNewPlan) {
      resultDietPlanId = await wizard.patientsController.generateDietPlan(
        wizard.patientId,
        wizard.firstConsultationId,
        wizard.requestId,
        startDate: startDate,
        currentWeight: currentWeight,
      );
      success = resultDietPlanId != null;
      if (!success) {
        errorMessage.value =
            wizard.patientsController.lastDietPlanGenerationError ??
            'Generation failed - please try again.';
      }
    } else if (isResumeBeforeMenu) {
      // Plan already exists; generate-menu below does the rest. A Draft
      // that reached workflowStatus 'targets_set' is always plan-item (see
      // createAndGenerateDietPlan) - default it so the generate-menu branch
      // still runs even if the resumed profile didn't carry a data model.
      if ((wizard.dataModel.value ?? '').isEmpty) {
        wizard.dataModel.value = 'plan-item';
      }
      resultDietPlanId = existingDietPlanId;
      success = true;
    } else {
      final response = await wizard.patientsController.regenerateWeek(
        wizard.patientId,
        existingDietPlanId,
        wizard.weeksToGenerate,
        currentWeight: currentWeight,
        startDate: startDate,
      );
      success = response != null && response['success'] == true;
      resultDietPlanId = existingDietPlanId;
      if (!success) {
        errorMessage.value = response?['message']?.toString() ?? 'Generation failed - please try again.';
      }
    }

    if (!success) {
      phase.value = GenerationPhase.failed;
      return;
    }

    wizard.dietPlanId.value = resultDietPlanId;
    if (isNewPlan) {
      wizard.dataModel.value = wizard.patientsController.lastDietPlanDataModel;
    }

    // v4.0: a plan-item plan has no meals yet at this point (creation
    // deliberately skips the old engine - see
    // controllers/dietician/dietPlanController.js's createAndGenerateDietPlan)
    // - call the wizard's own generate-menu endpoint now so "Generation"
    // still produces a filled-in week for this data model too.
    if (wizard.dataModel.value == 'plan-item') {
      // For a brand-new plan, wizard.weeksToGenerate is always just [1]
      // (patient_profile_view.dart's initial "Create Diet Plan" call site
      // never sets it - for days-array plans this doesn't matter, the
      // server derives the tier-based week count invisibly inside
      // createAndGenerateDietPlan, but that whole call is skipped for
      // plan-item plans, so generate-menu only ever gets whatever the
      // client explicitly sends). Re-derive it from the tier here instead,
      // mirroring utils/membershipTiers.js's TIER_INITIAL_WEEKS, so Silver
      // still gets all 4 weeks up front and Golden gets 1-2, matching the
      // exact cadence a days-array plan already gets for free.
      final weekNumbers = (isNewPlan || isResumeBeforeMenu) ? _initialWeeksForTier() : wizard.weeksToGenerate;
      final menuResult = await wizardService.generateMenu(
        patientId: wizard.patientId,
        dietPlanId: resultDietPlanId!,
        weekNumbers: weekNumbers,
      );
      if (menuResult == null || menuResult['success'] != true) {
        errorMessage.value = menuResult?['message']?.toString() ?? 'Menu generation failed - please try again.';
        phase.value = GenerationPhase.failed;
        return;
      }
      // generate-menu returns the review week's plan items in its own
      // response - seed the shared cache with it so the Generate review
      // screen renders straight from it, with no separate (heavy)
      // GET .../plan-items round-trip right after this one.
      final weekPlanItems = menuResult['data']?['weekPlanItems'];
      if (weekPlanItems is Map<String, dynamic>) {
        wizard.primeWeekPlanItems(weekPlanItems);
      }
    }

    // Now that a real dietPlanId exists, attach whatever supplements were
    // staged in Step 3. A supplement changes what getWeekPlanItems returns,
    // so drop the just-primed cache if any landed.
    if (Get.isRegistered<TimelineStepController>()) {
      final timelineController = Get.find<TimelineStepController>();
      if (timelineController.stagedSupplements.isNotEmpty) {
        supplementFlushFailures.value = await timelineController.flushToBackend(
          patientId: wizard.patientId,
          dietPlanId: resultDietPlanId!,
          week: wizard.targetWeek.value,
        );
      }
    }

    // Fallback: if generate-menu didn't carry the items (older backend) or
    // the supplement flush dropped the primed cache, warm it the old way so
    // the review screen still opens ready - capped so a wedged connection
    // can't sit on "Balancing calories..." forever.
    if (wizard.dataModel.value == 'plan-item' && !wizard.hasWeekPlanItemsCached) {
      await wizard
          .loadWeekPlanItems(forceRefresh: true)
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
    }

    phase.value = GenerationPhase.done;
  }

  /// Explicit, dietician-confirmed re-run of AI menu generation for a plan
  /// that already has items - the ONLY path allowed to discard the current
  /// plan items and generate a fresh set, unlike generate()'s guard above
  /// which exists specifically to prevent that from happening silently.
  /// Scoped to the week currently under review, not every week the plan
  /// might have, so regenerating doesn't wipe weeks the dietician isn't
  /// looking at right now.
  Future<bool> regenerateMenu() async {
    final dietPlanId = wizard.dietPlanId.value;
    if (dietPlanId == null || dietPlanId.isEmpty) return false;
    errorMessage.value = null;
    final result = await wizardService.generateMenu(
      patientId: wizard.patientId,
      dietPlanId: dietPlanId,
      weekNumbers: [wizard.targetWeek.value],
    );
    final success = result != null && result['success'] == true;
    if (!success) {
      errorMessage.value = result?['message']?.toString() ?? 'Regeneration failed - please try again.';
    } else {
      // A fresh menu replaces every plan item - the shared cache is now
      // stale for every step.
      wizard.invalidateWeekPlanItems();
    }
    phase.value = GenerationPhase.done;
    return success;
  }

  /// Mirrors utils/membershipTiers.js's TIER_INITIAL_WEEKS exactly - Silver
  /// gets all 4 weeks in the single initial "Create Diet Plan" action (no
  /// regeneration ever offered, see validateRegenerateRequest's explicit
  /// rejection for 'silver'), Golden gets weeks 1-2, Platinum (or an
  /// unrecognized/missing tier) gets week 1 only.
  List<int> _initialWeeksForTier() {
    final tier = wizard.patientsController.patientProfileModel.value?.status?.membershipTier?.toLowerCase();
    if (tier == 'silver') return [1, 2, 3, 4];
    if (tier == 'golden') return [1, 2];
    return [1];
  }

  Future<void> _advancePhaseAfter(GenerationPhase next, Duration delay) async {
    await Future.delayed(delay);
    // Don't overwrite a real outcome (done/failed) that already landed.
    if (phase.value == GenerationPhase.generatingMeals || phase.value == GenerationPhase.calculatingPortions) {
      phase.value = next;
    }
  }
}
