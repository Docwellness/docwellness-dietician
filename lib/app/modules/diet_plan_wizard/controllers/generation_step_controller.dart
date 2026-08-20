import 'dart:async';

import 'package:get/get.dart';

import 'timeline_step_controller.dart';
import 'wizard_controller.dart';

enum GenerationPhase { idle, generatingMeals, calculatingPortions, balancingCalories, done, failed }

/// Step 4 (Generation): triggers the actual diet-plan generation - reuses
/// PatientsController.generateDietPlan/regenerateWeek unchanged (the
/// existing, tier-gated, battle-tested orchestration - see that
/// controller's doc comments) rather than re-deriving membership-tier
/// cadence rules here. This step's own job is just the staged-progress UI
/// and, once a dietPlanId exists, flushing Step 3's staged supplements to it.
class GenerationStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();

  final Rx<GenerationPhase> phase = GenerationPhase.idle.obs;
  final RxnString errorMessage = RxnString();
  final RxInt supplementFlushFailures = 0.obs;

  Future<void> generate({double? currentWeight, DateTime? startDate}) async {
    phase.value = GenerationPhase.generatingMeals;
    errorMessage.value = null;

    final existingDietPlanId = wizard.dietPlanId.value;
    final isNewPlan = existingDietPlanId == null || existingDietPlanId.isEmpty;

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

    // Now that a real dietPlanId exists, attach whatever supplements were
    // staged in Step 3.
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

    phase.value = GenerationPhase.done;
  }

  Future<void> _advancePhaseAfter(GenerationPhase next, Duration delay) async {
    await Future.delayed(delay);
    // Don't overwrite a real outcome (done/failed) that already landed.
    if (phase.value == GenerationPhase.generatingMeals || phase.value == GenerationPhase.calculatingPortions) {
      phase.value = next;
    }
  }
}
