import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/views/select_diet_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreateDietPlanScreen extends StatefulWidget {
  final String patientId;
  final String firstConsultationId;
  final String requestId;
  final String name;

  /// For Week 2/3/4: pass the doctor-entered current weight here
  final double? currentWeightOverride;

  /// 1 = initial plan (calls AI generate), 2/3/4 = per-week flow (reuses existing plan)
  final int targetWeek;

  /// Non-null diet plan id is required when generating/regenerating specific
  /// week(s) of an already-created plan (see weeksToGenerate below).
  final String? dietPlanId;

  /// When set, this sheet operates in "generate mode" for exactly these week
  /// numbers instead of the targetWeek-based flow above - used for the
  /// tier-gated regeneration cadence (Golden weeks 3-4 together, Platinum
  /// one week at a time), calling the backend's generate-week endpoint
  /// rather than reusing an already-generated week's content.
  final List<int>? weeksToGenerate;

  const CreateDietPlanScreen({
    super.key,
    required this.firstConsultationId,
    required this.patientId,
    required this.requestId,
    required this.name,
    this.currentWeightOverride,
    this.targetWeek = 1,
    this.dietPlanId,
    this.weeksToGenerate,
  });

  @override
  State<CreateDietPlanScreen> createState() => _CreateDietPlanScreenState();
}

class _CreateDietPlanScreenState extends State<CreateDietPlanScreen> {
  String selectedCalories = "";
  bool isWeightGain = false;
  double _selectedWeeks = 0;

  String selectedMacros = "";

  List<String> selectedList = [];
  final PatientsController controller = Get.find<PatientsController>();

  // Weight text field controller - editable for every week, seeded from the
  // patient's latest known weight (kept in sync with their logged progress).
  final TextEditingController _weightController = TextEditingController();
  double? _enteredWeight;

  DateTime _selectedStartDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final health = controller.patientProfileModel.value?.healthSummary;
    final initialWeight =
        widget.currentWeightOverride ?? (health?.weight ?? 0).toDouble();
    _enteredWeight = initialWeight;
    _weightController.text = initialWeight > 0 ? initialWeight.toString() : '';

    final parsedStart = _parseDdMmYyyy(health?.startDateForDiet ?? '');
    if (parsedStart != null) _selectedStartDate = parsedStart;
  }

  DateTime? _parseDdMmYyyy(String s) {
    try {
      final parts = s.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // ================= AGE =================
  int _calculateAge(String dob) {
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

  // ================= ACTIVITY =================
  // Matched case-insensitively against the exact option labels a patient
  // picks from (see activity_level_view.dart's activityLevelOptions:
  // 'Sedentary' / 'Lightly Activity' / 'Moderately Activity' / 'Very
  // Active') - previously 'Moderately Activity' (the actual stored value)
  // didn't match any case here and silently fell through to the default.
  double _activityMultiplier(String level) {
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

  // ================= BMR =================
  double _calculateBMR({
    required bool isMale,
    required double weight,
    required double height,
    required int age,
  }) {
    return isMale
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;
  }

  // ================= SAFETY =================
  double _applySafety(double calories, bool isMale) {
    if (isMale && calories < 1500) return 1500;
    if (!isMale && calories < 1200) return 1200;
    return calories;
  }

  // ================= WEEKLY LOSS =================

  double weeklyWeightChangeKg(int calorieDifference) {
    return (calorieDifference * 7) / 7700;
  }

  // ================= MACROS =================
  int _gramsForPercent(int budgetCal, int percent, int kcalPerGram) {
    if (budgetCal <= 0) return 0;
    return (budgetCal * percent / 100 / kcalPerGram).round();
  }

  // Standard dietary-guideline heuristic: ~14g fiber per 1000 kcal.
  int _fiberGramsForBudget(int budgetCal) {
    if (budgetCal <= 0) return 0;
    return (budgetCal / 1000 * 14).round();
  }

  @override
  Widget build(BuildContext context) {
    final profile = controller.patientProfileModel.value;

    if (profile == null ||
        profile.basic == null ||
        profile.healthSummary == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        ),
      );
    }

    final basic = profile.basic!;
    final health = profile.healthSummary!;

    final bool isMale = (basic.gender ?? '').toLowerCase() == 'male';

    final int age = _calculateAge(basic.dateOfBirth ?? '01-01-2000');

    // Doctor-entered/confirmed weight, editable for every week.
    final double weight = _enteredWeight ?? (health.weight ?? 0).toDouble();

    final double height = (health.height ?? 0).toDouble();

    final String activity = health.activityLevel ?? 'Lightly active';

    final double targetWeight =
        double.tryParse(
          (health.targetWeight ?? '0').replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;

    final double bmr = _calculateBMR(
      isMale: isMale,
      weight: weight,
      height: height,
      age: age,
    );

    final double tdee = bmr * _activityMultiplier(activity);

    final plans = [
      {
        "title": "Gentle",
        "desc": "Easy to do, ideal for beginners or those with health concerns",
        "deficit": 250,
      },
      {
        "title": "Steady",
        "desc": "Moderate, sustainable long-term preferred by most",
        "deficit": 500,
      },
      {
        "title": "Accelerated",
        "desc": "High difficulty, challenging for quick results",
        "deficit": 750,
      },
      {
        "title": "Extreme",
        "desc": "The most aggressive plan for fastest results",
        "deficit": 1000,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Center(
                child: Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Color(0xff79747E),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  CustomText(
                    text: widget.weeksToGenerate != null
                        ? (widget.weeksToGenerate!.length > 1
                              ? 'Generate Weeks ${widget.weeksToGenerate!.join('-')}'
                              : 'Generate Week ${widget.weeksToGenerate!.first}')
                        : 'Create Diet Plan',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
              Divider(color: Color(0xff9DA4AE)),

              // Starting date - first field, drives the summary card and the
              // end-date estimate below.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: "Starting Date",
                      fontSize: 21,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff530630),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final today = DateTime.now();
                        // _selectedStartDate may be seeded from the patient's
                        // existing startDateForDiet, which can predate "today" -
                        // showDatePicker asserts initialDate >= firstDate, so
                        // the floor must never be later than the seeded value.
                        final firstDate = _selectedStartDate.isBefore(today)
                            ? _selectedStartDate
                            : today;
                        final lastDate = today.add(const Duration(days: 60));
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedStartDate,
                          firstDate: firstDate,
                          lastDate: _selectedStartDate.isAfter(lastDate)
                              ? _selectedStartDate
                              : lastDate,
                        );
                        if (picked != null) {
                          setState(() => _selectedStartDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xffFEF6FB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xff851653),
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xffFAA7E0),
                            ),
                          ),
                        ),
                        child: CustomText(
                          text: DateFormat(
                            'MMM d, yyyy',
                          ).format(_selectedStartDate),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xff1F2A37),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ===== TOP CARD =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(
                  builder: (context) {
                    final startDateStr = DateFormat(
                      'MMM d, yyyy',
                    ).format(_selectedStartDate);
                    final endDate = _selectedWeeks > 0
                        ? _selectedStartDate.add(
                            Duration(days: (_selectedWeeks * 7).round()),
                          )
                        : null;
                    final endDateStr = endDate != null
                        ? DateFormat('MMM d, yyyy').format(endDate)
                        : '—';

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 12,
                        right: 27,
                        bottom: 27,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xffFDF2FA)),
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              children: [
                                CustomText(
                                  text: '${widget.name} will Reach ',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Color(0xff384250),
                                ),
                                CustomText(
                                  text: '${targetWeight.round()} kg ',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Color(0xff384250),
                                ),
                                CustomText(
                                  text: 'by ',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 18,
                                  color: Color(0xff384250),
                                ),
                                CustomText(
                                  text: endDateStr,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Color(0xff384250),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 3),
                                  child: CustomText(
                                    text: '    by starting ',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color(0xff6C737F),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 3),
                                  child: CustomText(
                                    text: 'on ',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color(0xff6C737F),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 3),
                                  child: CustomText(
                                    text: startDateStr,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color(0xff6C737F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 26),
                            child: Image.asset(
                              'assets/icons/Calendar.png',
                              height: 24,
                              width: 24,
                              fit: BoxFit.cover,
                              color: Color(0xff0D121C),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Current weight - editable for every week.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                      text: "Current Weight",
                      fontSize: 21,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff530630),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter current weight',
                        suffixText: 'kg',
                        suffixStyle: const TextStyle(
                          color: Color(0xff851653),
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: const Color(0xffFEF6FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xffFAA7E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xff851653),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setState(() {
                            _enteredWeight = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CustomText(
                  text: "Calories",

                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff530630),
                ),
              ),
              const SizedBox(height: 10),

              Column(
                children: plans.map((plan) {
                  final int deficit = plan["deficit"] as int;

                  isWeightGain = (health.primaryGoal ?? '')
                      .toLowerCase()
                      .contains('gain');

                  final double calorieBudget = _applySafety(
                    isWeightGain ? tdee + deficit : tdee - deficit,
                    isMale,
                  );

                  final double weeklyChange = isWeightGain
                      ? weeklyWeightChangeKg(deficit)
                      : weeklyWeightChangeKg(deficit);

                  final double weightDiff = (weight - targetWeight).abs();

                  final double weeks = weeklyChange <= 0
                      ? 0
                      : weightDiff / weeklyChange;

                  final String durationStr = weeks <= 0
                      ? '—'
                      : weeks.floor() == weeks.ceil()
                      ? '${weeks.round()} Weeks'
                      : '${weeks.floor()} - ${weeks.ceil()} Weeks';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: calorieBox(
                      plan["title"] as String,
                      plan["desc"] as String,
                      budget: "${calorieBudget.round()} Cal",
                      deficit: "$deficit Cal",
                      loss: "${weeklyChange.toStringAsFixed(2)} kg",
                      duration: durationStr,
                      weeks: weeks,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomText(
                  text: "Macros",

                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff530630),
                ),
              ),
              const SizedBox(height: 10),

              Builder(
                builder: (context) {
                  final int selectedBudgetCal =
                      (controller.selectedCalorieStrategy['calorieBudget']
                              as num?)
                          ?.round() ??
                      0;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: macrosBox(
                          "Balanced",
                          "Best for those prioritizing balanced nutrition and overall wellness",
                          fatPercent: 30,
                          carbsPercent: 50,
                          proteinPercent: 20,
                          budgetCal: selectedBudgetCal,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: macrosBox(
                          "Low-Carb",
                          "Best for those seeking to reduce carbs for weight and health management",
                          fatPercent: 40,
                          carbsPercent: 30,
                          proteinPercent: 30,
                          budgetCal: selectedBudgetCal,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              // ACTION BUTTON — Week 1: generate AI plan | Week 2/3/4: use existing plan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => CustomButton(
                    isLoading: controller.generateDietPlanLoading.value,
                    onTap: () async {
                      // ── Validate weight (every week) ──
                      final w = double.tryParse(_weightController.text.trim());
                      if (w == null || w <= 0) {
                        Get.snackbar(
                          'Missing Weight',
                          'Please enter the patient\'s current weight',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }
                      controller.currentWeightForWeek.value = w;

                      // ── Validate selections ──
                      if (selectedCalories.isEmpty) {
                        Get.snackbar(
                          'Missing Selection',
                          'Please select a Calorie option (Gentle, Steady, Accelerated, or Extreme)',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }
                      if (selectedMacros.isEmpty) {
                        Get.snackbar(
                          'Missing Selection',
                          'Please select a Macros option (Balanced or Low-Carb)',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }

                      final activeDietPlanId =
                          controller
                              .patientProfileModel
                              .value
                              ?.status
                              ?.activeDietPlanId ??
                          '';

                      if (widget.weeksToGenerate != null) {
                        // ── Tier-gated regeneration of specific week(s) ──
                        final targetDietPlanId =
                            widget.dietPlanId ?? activeDietPlanId;
                        if (targetDietPlanId.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'No diet plan found to generate weeks for.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        final response = await controller.regenerateWeek(
                          widget.patientId,
                          targetDietPlanId,
                          widget.weeksToGenerate!,
                          currentWeight: w,
                        );
                        if (response == null || response['success'] != true) {
                          Get.snackbar(
                            'Could not generate',
                            response?['message']?.toString() ??
                                'Please try again.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                            duration: const Duration(seconds: 4),
                          );
                          return;
                        }
                        if (controller.showGenerateDietPlanSheet.value ==
                            true) {
                          await controller.getDraftDietOptions(
                            widget.patientId,
                            targetDietPlanId,
                            widget.weeksToGenerate!.first,
                          );
                          if (!context.mounted) return;
                          Get.to(
                            () => SelectDietSheet(
                              dietPlanId: targetDietPlanId,
                              patientId: widget.patientId,
                            ),
                          );
                        }
                      } else if (widget.targetWeek == 1) {
                        // ── Week 1: original AI-generate flow ──
                        if (widget.firstConsultationId.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'First consultation ID is missing. Please refresh.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        final newDietPlanId = await controller.generateDietPlan(
                          widget.patientId,
                          widget.firstConsultationId,
                          widget.requestId,
                          startDate: _selectedStartDate,
                          currentWeight: w,
                        );
                        if (newDietPlanId == null || newDietPlanId.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Diet plan generation failed. Please try again.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        if (controller.showGenerateDietPlanSheet.value ==
                            true) {
                          await controller.getDraftDietOptions(
                            widget.patientId,
                            newDietPlanId,
                            1,
                          );
                          if (!context.mounted) return;
                          Get.to(
                            () => SelectDietSheet(
                              dietPlanId: newDietPlanId,
                              patientId: widget.patientId,
                            ),
                          );
                        }
                      } else {
                        // ── Week 2/3/4: reuse existing diet plan, skip AI generation ──
                        if (activeDietPlanId.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'No diet plan found for this patient.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }
                        await controller.getDraftDietOptions(
                          widget.patientId,
                          activeDietPlanId,
                          widget.targetWeek,
                        );

                        if (!context.mounted) return;
                        // Open SelectDietSheet as its own screen
                        Get.to(
                          () => SelectDietSheet(
                            dietPlanId: activeDietPlanId,
                            patientId: widget.patientId,
                          ),
                        );
                      }
                    },
                    text: widget.weeksToGenerate != null
                        ? (widget.weeksToGenerate!.length > 1
                              ? 'Generate Weeks ${widget.weeksToGenerate!.join('-')}'
                              : 'Generate Week ${widget.weeksToGenerate!.first}')
                        : widget.targetWeek == 1
                        ? 'Generate Diet Plan'
                        : 'Select Meals for Week ${widget.targetWeek}',
                    isOutline: false,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===== CALORIES CARD =====
  Widget calorieBox(
    String title,
    String subtitle, {
    required String budget,
    required String deficit,
    required String loss,
    required String duration,
    required double weeks,
  }) {
    bool isSelected = selectedCalories == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCalories = title;
          _selectedWeeks = weeks;

          // Safely parse durationWeeks: strip non-digits from the first part
          // e.g. "12 Weeks" -> "12", "8 - 9 Weeks" -> "8", "—" -> 0
          final durationFirstPart = duration.split(' - ').first;
          final durationDigits = durationFirstPart.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final parsedDurationWeeks = int.tryParse(durationDigits) ?? 0;

          // Safely parse budget: strip everything except digits
          final budgetDigits = budget.replaceAll(RegExp(r'[^0-9]'), '');
          final parsedBudget = int.tryParse(budgetDigits) ?? 0;

          // Safely parse deficit
          final deficitDigits = deficit.replaceAll(RegExp(r'[^0-9]'), '');
          final parsedDeficit = int.tryParse(deficitDigits) ?? 0;

          // Safely parse weekly weight change
          final lossDigits = loss.replaceAll(RegExp(r'[^0-9.]'), '');
          final parsedLoss = double.tryParse(lossDigits) ?? 0.0;

          // Store the detailed info for sending
          controller.selectedCalorieStrategy = {
            "name": title,
            "calorieBudget": parsedBudget,
            "calorieDeficit": parsedDeficit,
            "weeklyWeightChangeKg": parsedLoss,
            "durationWeeks": parsedDurationWeeks,
          };
        });
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xffFDF2FA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: title.toUpperCase(),

                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff851653),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected
                        ? const Color(0xff851653)
                        : Color(0xff49454F),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: CustomText(
                text: subtitle,

                fontSize: 13,
                color: Color(0xff6C737F),
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 1),
            Divider(color: Color(0xffFCCEEF)),

            infoRow("Calorie Budget", budget, 'assets/icons/diet_icon_1.png'),
            infoRow("Calorie Deficit", deficit, 'assets/icons/diet_icon_2.png'),
            infoRow(
              isWeightGain ? "Weekly weight gain" : "Weekly weight loss",
              loss,
              'assets/icons/diet_icon_3.png',
            ),
            infoRow("Duration", duration, 'assets/icons/diet_icon_4.png'),
          ],
        ),
      ),
    );
  }

  // ===== MACROS CARD =====
  Widget macrosBox(
    String title,
    String subtitle, {
    required int fatPercent,
    required int carbsPercent,
    required int proteinPercent,
    required int budgetCal,
  }) {
    bool isSelected = selectedMacros == title;

    final int fatGrams = _gramsForPercent(budgetCal, fatPercent, 9);
    final int carbsGrams = _gramsForPercent(budgetCal, carbsPercent, 4);
    final int proteinGrams = _gramsForPercent(budgetCal, proteinPercent, 4);
    final int fiberGrams = _fiberGramsForBudget(budgetCal);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMacros = title;

          controller.selectedMacroStrategy = {
            "name": title,
            "fatPercent": fatPercent,
            "carbsPercent": carbsPercent,
            "proteinPercent": proteinPercent,
            "fiberGrams": fiberGrams,
          };
        });
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xffFDF2FA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: title,

                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff851653),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected
                        ? const Color(0xff851653)
                        : Color(0xff49454F),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: CustomText(
                text: subtitle,

                fontSize: 13,
                color: Color(0xff6C737F),
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 12),
            infoRow(
              "Fat",
              "$fatPercent% (${fatGrams}g)",
              'assets/icons/diet_icon_5.png',
            ),
            infoRow(
              "Net Carbs",
              "$carbsPercent% (${carbsGrams}g)",
              'assets/icons/diet_icon_6.png',
            ),
            infoRow(
              "Protein",
              "$proteinPercent% (${proteinGrams}g)",
              'assets/icons/diet_icon_7.png',
            ),
            infoRowIcon("Fiber", "${fiberGrams}g", Icons.grass_outlined),
          ],
        ),
      ),
    );
  }

  // ===== INFO ROW =====
  Widget infoRow(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(icon, height: 14, width: 14, fit: BoxFit.contain),
          SizedBox(width: 10),
          CustomText(
            text: label,
            fontWeight: FontWeight.w400,
            fontSize: 17,
            color: Color(0xff851653),
          ),
          Spacer(),
          CustomText(
            text: value,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xff851653),
          ),
        ],
      ),
    );
  }

  // Same as infoRow but for rows with no matching PNG asset (e.g. Fiber).
  Widget infoRowIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xff851653)),
          SizedBox(width: 10),
          CustomText(
            text: label,
            fontWeight: FontWeight.w400,
            fontSize: 17,
            color: Color(0xff851653),
          ),
          Spacer(),
          CustomText(
            text: value,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
