import 'package:docwellnesdoc/app/modules/patients/utils/diet_target_calculations.dart';
import 'package:get/get.dart';

import 'wizard_controller.dart';

/// Step 2 (Targets): calorie/macro strategy card selection. Uses the same
/// shared math as show_diet_level_sheet.dart's CreateDietPlanScreen (see
/// diet_target_calculations.dart) so both UIs propose identical numbers for
/// the same patient - only this step's presentation (wizard-styled cards)
/// is new.
class TargetsStepController extends GetxController {
  final WizardController wizard = Get.find<WizardController>();

  final RxnString selectedCalorieTitle = RxnString();
  final RxnString selectedMacroTitle = RxnString();

  final RxList<CalorieTierResult> calorieTiers = <CalorieTierResult>[].obs;
  final RxList<MacroOptionResult> macroOptions = <MacroOptionResult>[].obs;

  @override
  void onInit() {
    super.onInit();
    _recompute();

    // Re-open with whatever was previously selected for this patient (e.g.
    // navigating back a step, or resuming after a refresh) instead of a
    // blank form.
    final existing = wizard.patientsController.patientProfileModel.value
        ?.activePlanStrategy;
    if (existing?.calorieStrategy?.name != null) {
      selectedCalorieTitle.value = existing!.calorieStrategy!.name;
    }
    if (existing?.macroStrategy?.name != null) {
      selectedMacroTitle.value = existing!.macroStrategy!.name;
    }
  }

  void _recompute() {
    final profile = wizard.patientsController.patientProfileModel.value;
    final basic = profile?.basic;
    final health = profile?.healthSummary;
    if (basic == null || health == null) return;

    final isMale = (basic.gender ?? '').toLowerCase() == 'male';
    final age = calculateAge(basic.dateOfBirth ?? '01-01-2000');
    final weight = (health.weight ?? 0).toDouble();
    final height = (health.height ?? 0).toDouble();
    final activity = health.activityLevel ?? 'Lightly active';
    final targetWeight =
        double.tryParse(
          (health.targetWeight ?? '0').replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
    final isWeightGain = (health.primaryGoal ?? '').toLowerCase().contains(
      'gain',
    );

    calorieTiers.assignAll(
      computeCalorieTiers(
        isMale: isMale,
        weight: weight,
        height: height,
        age: age,
        activityLevel: activity,
        targetWeight: targetWeight,
        isWeightGain: isWeightGain,
      ),
    );
  }

  CalorieTierResult? get selectedCalorieTier => calorieTiers
      .cast<CalorieTierResult?>()
      .firstWhere((t) => t?.title == selectedCalorieTitle.value, orElse: () => null);

  void selectCalorieTier(String title) {
    selectedCalorieTitle.value = title;
    final tier = calorieTiers.cast<CalorieTierResult?>().firstWhere(
      (t) => t?.title == title,
      orElse: () => null,
    );
    if (tier != null) {
      wizard.patientsController.selectedCalorieStrategy =
          tier.toCalorieStrategyPayload();
    }
    _recomputeMacroOptions();
  }

  void _recomputeMacroOptions() {
    final budget =
        (wizard.patientsController.selectedCalorieStrategy['calorieBudget']
                as num?)
            ?.round() ??
        0;
    macroOptions.assignAll(computeMacroOptions(budget));
  }

  void selectMacroOption(String title) {
    selectedMacroTitle.value = title;
    final option = macroOptions.cast<MacroOptionResult?>().firstWhere(
      (o) => o?.title == title,
      orElse: () => null,
    );
    if (option != null) {
      wizard.patientsController.selectedMacroStrategy =
          option.toMacroStrategyPayload();
    }
  }

  bool get canContinue =>
      selectedCalorieTitle.value != null && selectedMacroTitle.value != null;
}
