/// Shared calorie/macro target math, extracted from
/// show_diet_level_sheet.dart's CreateDietPlanScreen (the original single-
/// screen "Create Diet Plan" flow) so both that screen and the new 5-Step
/// Wizard's Targets step (diet_plan_wizard/) compute identical numbers from
/// one place - this is clinically-relevant math (BMR/TDEE/safety-floor), not
/// display logic, so it must never drift between the two UIs.
library;

/// Mifflin-St Jeor age calc from a dd-mm-yyyy date-of-birth string, with a
/// safe fallback if parsing fails.
int calculateAge(String dob) {
  try {
    final parts = dob.split('-'); // dd-mm-yyyy
    final birthDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  } catch (_) {
    return 25; // safe fallback
  }
}

/// Matched case-insensitively against the exact option labels a patient
/// picks from (see activity_level_view.dart's activityLevelOptions:
/// 'Sedentary' / 'Lightly Activity' / 'Moderately Activity' / 'Very Active').
double activityMultiplier(String level) {
  switch (level.trim().toLowerCase()) {
    case 'sedentary':
      return 1.2;
    case 'lightly activity':
    case 'lightly active':
      return 1.375;
    case 'moderately activity':
    case 'moderately active':
      return 1.55;
    case 'very activity':
    case 'very active':
      return 1.725;
    case 'extra activity':
    case 'extra active':
      return 1.9;
    default:
      return 1.375;
  }
}

/// Mifflin-St Jeor BMR formula.
double calculateBmr({
  required bool isMale,
  required double weight,
  required double height,
  required int age,
}) {
  return isMale
      ? (10 * weight) + (6.25 * height) - (5 * age) + 5
      : (10 * weight) + (6.25 * height) - (5 * age) - 161;
}

/// Clinical safety floor - never propose a budget below this regardless of
/// how aggressive the selected deficit is.
double applyCalorieSafetyFloor(double calories, bool isMale) {
  if (isMale && calories < 1500) return 1500;
  if (!isMale && calories < 1200) return 1200;
  return calories;
}

/// 7700 kcal ≈ 1kg of body weight (the standard rule-of-thumb conversion).
double weeklyWeightChangeKg(int calorieDifference) {
  return (calorieDifference * 7) / 7700;
}

int gramsForPercent(int budgetCal, int percent, int kcalPerGram) {
  if (budgetCal <= 0) return 0;
  return (budgetCal * percent / 100 / kcalPerGram).round();
}

/// Standard dietary-guideline heuristic: ~14g fiber per 1000 kcal.
int fiberGramsForBudget(int budgetCal) {
  if (budgetCal <= 0) return 0;
  return (budgetCal / 1000 * 14).round();
}

/// The 4 fixed calorie-strategy tiers (title, description, deficit) - same
/// data both CreateDietPlanScreen and the wizard's Targets step render as
/// selectable cards.
const List<({String title, String description, int deficit})>
calorieStrategyTiers = [
  (
    title: 'Gentle',
    description: 'Easy to do, ideal for beginners or those with health concerns',
    deficit: 250,
  ),
  (
    title: 'Steady',
    description: 'Moderate, sustainable long-term preferred by most',
    deficit: 500,
  ),
  (
    title: 'Accelerated',
    description: 'High difficulty, challenging for quick results',
    deficit: 750,
  ),
  (
    title: 'Extreme',
    description: 'The most aggressive plan for fastest results',
    deficit: 1000,
  ),
];

/// The 2 fixed macro-strategy options (title, description, percentages).
const List<({String title, String description, int fatPercent, int carbsPercent, int proteinPercent})>
macroStrategyOptions = [
  (
    title: 'Balanced',
    description: 'Best for those prioritizing balanced nutrition and overall wellness',
    fatPercent: 30,
    carbsPercent: 50,
    proteinPercent: 20,
  ),
  (
    title: 'Low-Carb',
    description: 'Best for those seeking to reduce carbs for weight and health management',
    fatPercent: 40,
    carbsPercent: 30,
    proteinPercent: 30,
  ),
];

/// Everything CreateDietPlanScreen/the wizard need to render one calorie-tier
/// card and to build the calorieStrategy payload if it's selected.
class CalorieTierResult {
  final String title;
  final String description;
  final int deficit;
  final double calorieBudget;
  final double weeklyChangeKg;
  final double weeksToTarget;

  const CalorieTierResult({
    required this.title,
    required this.description,
    required this.deficit,
    required this.calorieBudget,
    required this.weeklyChangeKg,
    required this.weeksToTarget,
  });

  Map<String, dynamic> toCalorieStrategyPayload() => {
    'name': title,
    'calorieBudget': calorieBudget.round(),
    'calorieDeficit': deficit,
    'weeklyWeightChangeKg': weeklyChangeKg,
    'durationWeeks': weeksToTarget <= 0 ? 0 : weeksToTarget.floor(),
  };
}

/// Computes every calorie tier's live numbers for one patient - the same
/// `plans.map` loop CreateDietPlanScreen's build() runs inline, factored out
/// so the wizard's Targets step doesn't have to re-derive it.
List<CalorieTierResult> computeCalorieTiers({
  required bool isMale,
  required double weight,
  required double height,
  required int age,
  required String activityLevel,
  required double targetWeight,
  required bool isWeightGain,
}) {
  final bmr = calculateBmr(isMale: isMale, weight: weight, height: height, age: age);
  final tdee = bmr * activityMultiplier(activityLevel);

  return calorieStrategyTiers.map((tier) {
    final calorieBudget = applyCalorieSafetyFloor(
      isWeightGain ? tdee + tier.deficit : tdee - tier.deficit,
      isMale,
    );
    final weeklyChange = isWeightGain
        ? weeklyWeightChangeKg(tier.deficit)
        : weeklyWeightChangeKg(tier.deficit);
    final weightDiff = (weight - targetWeight).abs();
    final weeks = weeklyChange <= 0 ? 0.0 : weightDiff / weeklyChange;

    return CalorieTierResult(
      title: tier.title,
      description: tier.description,
      deficit: tier.deficit,
      calorieBudget: calorieBudget,
      weeklyChangeKg: weeklyChange,
      weeksToTarget: weeks,
    );
  }).toList();
}

/// Everything needed to render one macro-option card and build its payload.
class MacroOptionResult {
  final String title;
  final String description;
  final int fatPercent;
  final int carbsPercent;
  final int proteinPercent;
  final int fatGrams;
  final int carbsGrams;
  final int proteinGrams;
  final int fiberGrams;

  const MacroOptionResult({
    required this.title,
    required this.description,
    required this.fatPercent,
    required this.carbsPercent,
    required this.proteinPercent,
    required this.fatGrams,
    required this.carbsGrams,
    required this.proteinGrams,
    required this.fiberGrams,
  });

  Map<String, dynamic> toMacroStrategyPayload() => {
    'name': title,
    'fatPercent': fatPercent,
    'carbsPercent': carbsPercent,
    'proteinPercent': proteinPercent,
    'fiberGrams': fiberGrams,
  };
}

List<MacroOptionResult> computeMacroOptions(int selectedBudgetCal) {
  return macroStrategyOptions.map((option) {
    return MacroOptionResult(
      title: option.title,
      description: option.description,
      fatPercent: option.fatPercent,
      carbsPercent: option.carbsPercent,
      proteinPercent: option.proteinPercent,
      fatGrams: gramsForPercent(selectedBudgetCal, option.fatPercent, 9),
      carbsGrams: gramsForPercent(selectedBudgetCal, option.carbsPercent, 4),
      proteinGrams: gramsForPercent(selectedBudgetCal, option.proteinPercent, 4),
      fiberGrams: fiberGramsForBudget(selectedBudgetCal),
    );
  }).toList();
}
