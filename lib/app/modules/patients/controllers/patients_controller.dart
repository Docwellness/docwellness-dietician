import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart';
import 'package:docwellnesdoc/app/models/journey_image_model.dart';
import 'package:docwellnesdoc/app/models/patient_list_model.dart';
import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/models/update_ai_diet_plain_model.dart';
import 'package:docwellnesdoc/app/modules/patients/services/patient_service.dart';
import 'package:docwellnesdoc/app/modules/patients/views/questions_view.dart';
import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/modules/performance/services/consultation_form_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PatientsController extends GetxController {
  Rx<PatientProfileModel?> patientProfileModel = Rx<PatientProfileModel?>(null);
  Rx<DietPlanWeekData?> dietPlanWeekData = Rx<DietPlanWeekData?>(null);

  final PatientService service = PatientService();

  // Patient lists for each tab
  RxList<OngoingPatientModel> ongoingPatients = <OngoingPatientModel>[].obs;
  RxList<NewPatientModel> newPatients = <NewPatientModel>[].obs;
  RxList<PastPatientModel> pastPatients = <PastPatientModel>[].obs;

  // Loading states for each tab
  RxBool isOngoingLoading = false.obs;
  RxBool isNewLoading = false.obs;
  RxBool isPastLoading = false.obs;

  // Search query
  RxString searchQuery = ''.obs;

  RxBool isProfileLoading = false.obs;
  RxBool isConsultationSending = false.obs;

  final ImagePicker picker = ImagePicker();
  TextEditingController totalAmount = TextEditingController();
  TextEditingController pendingAmount = TextEditingController();
  TextEditingController totalApaymentDesmount = TextEditingController();
  TextEditingController paymentDes = TextEditingController();

  Map<String, dynamic> selectedCalorieStrategy = {};
  Map<String, dynamic> selectedMacroStrategy = {};

  RxBool showBasicInfo = false.obs;
  RxBool showBmiCard = false.obs;

  RxBool showAllDietSendingLoading = false.obs;
  RxBool showWeekDietSendingLoading = false.obs;

  RxBool showFirstConsultationiInfo = false.obs;
  RxBool showPaymentInfo = false.obs;
  RxBool isPaymentRequestSending = false.obs;
  RxBool showSelectedDeitLoading = false.obs;
  RxBool updatingWeekItem = false.obs;

  RxBool generateDietPlanLoading = false.obs;
  RxBool activateDietPlanLoading = false.obs;
  RxBool rejectPaymentLoading = false.obs;
  RxBool confirmRenewalPaymentLoading = false.obs;
  RxBool isProofLoading = false.obs;
  RxBool showGenerateDietPlanSheet = false.obs;
  RxBool showGeneratedDietPlanLoading = false.obs;
  RxBool isAllQuestionLoading = false.obs;
  RxString selectedPortionFromLogMealSheet = ''.obs;
  RxString selectedWeek = "Week 1".obs;
  RxString proofPic = "".obs;
  RxString paymentProofId = "".obs;
  RxString paymentProofStatus = "".obs;

  // Coupon info from patient payment
  RxString paymentCouponCode = ''.obs;
  RxDouble paymentDiscountPercentage = 0.0.obs;
  RxDouble paymentOriginalAmount = 0.0.obs;
  TextEditingController rejectionNoteController = TextEditingController();

  RxDouble totalCalories = 0.0.obs;
  RxDouble totalProtein = 0.0.obs;
  RxDouble totalFat = 0.0.obs;
  RxDouble totalCarbs = 0.0.obs;
  RxDouble totalFiber = 0.0.obs;

  RxList<Recipe> selectedRecipes = <Recipe>[].obs;

  RxList<WeeklyDietPlan> weeklyDietPlans = <WeeklyDietPlan>[].obs;

  /// Current weight entered by doctor for week 2/3/4
  RxDouble currentWeightForWeek = 0.0.obs;

  RxString getSelectedShift = "Breakfast".obs;

  RxList<RecipeModel> getShiftMeals = <RecipeModel>[].obs;

  /// FULL week's meals (all servingTimes) for selected week
  RxList<DailyMeal> selectedWeekMeals = <DailyMeal>[].obs;

  /// Meals filtered by currently selected shift (servingTime)
  RxList<DailyMeal> shiftMeals = <DailyMeal>[].obs;

  /// Currently selected shift (e.g. "Breakfast", "Morning Drink", ...)
  RxString selectedShift = "Breakfast".obs;

  /// Currently selected day-group in the draft-review screen - one of
  /// 'Monday' (repeats Friday), 'Tuesday' (repeats Saturday), 'Wednesday'
  /// (repeats Sunday), 'Thursday' (unique). See backend utils/dayGroups.js.
  RxString selectedDayGroup = 'Monday'.obs;

  static const List<String> dayGroups = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
  ];

  /// Full recipe options pool (AI's pick(s) plus every other matching
  /// recipe, incl. sides/salads cross-listed into Lunch/Dinner/Evening
  /// Snack - see backend utils/dietPlanOptions.js) for a not-yet-finalized
  /// (Draft) diet plan's week - powers select_diet_sheet.dart. Deliberately
  /// separate from `dietPlanWeekData` below, which is the finalized-week
  /// screen's own state, to avoid the two screens silently clobbering each
  /// other's data through this shared controller singleton.
  Rx<DietPlanWeekData?> draftDietOptions = Rx<DietPlanWeekData?>(null);

  /// The current tab's full options list (AI's pick(s) already selected -
  /// see weekSelectedRecipes) for the draft-review screen.
  RxList<Recipe> shiftOptions = <Recipe>[].obs;

  /// Slots the dietician has asked to see the full options pool for (via
  /// [toggleShowMoreOptions]), keyed by servingTime - collapsed by default so
  /// switching tabs doesn't show an overwhelming list, but stays expanded
  /// across tab switches once opened.
  RxSet<String> expandedShifts = <String>{}.obs;

  /// How many close alternatives to preview alongside the selections before
  /// the dietician has to tap "show more".
  static const int _previewAlternativesCount = 3;

  Rx<DietPlanData?> dietPlanData = Rx<DietPlanData?>(null);
  RxMap<int, List<Recipe>> weekSelectedRecipes = <int, List<Recipe>>{}.obs;

  /// Servings multiplier per selected recipe, keyed by id + servingTime (see
  /// servingsKey) rather than id alone - the same recipe (e.g. Chapati) can
  /// be selected in both Lunch and Dinner in the same week with different
  /// counts (3 chapatis at Lunch, 2 at Dinner), and those must not collide.
  /// Values: e.g. 3 for "3 chapatis", or 400 for "400g of Chole" (gram/ml-
  /// based items store the adjusted absolute quantity, not a multiplier -
  /// see incrementServings/calculateTotalsForWeek). Defaults to the
  /// recipe's own baseServingQuantity (1x) when a card is first selected.
  RxMap<String, num> selectedServings = <String, num>{}.obs;

  /// Same shape as [selectedServings], for the second independently-
  /// adjustable component of a compound snack (e.g. the seeds/chikki
  /// mix-in alongside a fruit - see Recipe.hasSecondaryComponent). Empty
  /// for every ordinary single-quantity recipe.
  RxMap<String, num> selectedSecondaryServings = <String, num>{}.obs;

  /// Composite key for [selectedServings]/[selectedSecondaryServings] - see
  /// those fields' doc comments. Includes dayGroup (not just id+servingTime)
  /// since the same recipe can be legitimately selected under two different
  /// day-groups' same slot with different counts (e.g. 3 chapatis at
  /// Monday-group's Lunch, 2 at Tuesday-group's Lunch).
  String servingsKey(Recipe r) => '${r.id}|${r.servingTime}|${r.dayGroup}';

  /// Tracks which weeks the user has manually toggled selections on.
  /// If a week is in this set and its selection list is empty, totals show 0.
  final RxSet<int> _userInteractedWeeks = <int>{}.obs;

  RxBool isProfileDeactivated = false.obs;

  // ===== Tracking Data (Charts) =====
  Rx<TrackingData?> trackingData = Rx<TrackingData?>(null);
  RxBool isTrackingLoading = false.obs;
  // Single unified period for all charts (since they share one API call)
  RxString trackingTimePeriod = 'week'.obs;

  // ===== Journey Images =====
  RxList<JourneyImageModel> journeyImages = <JourneyImageModel>[].obs;
  // Auto-generated milestone journey cards from body logs
  RxList<JourneyImageModel> autoJourneyCards = <JourneyImageModel>[].obs;
  RxBool isJourneyLoading = false.obs;
  RxBool isAutoMilestonesLoaded = false.obs;
  RxBool isJourneyUploading = false.obs;

  // ===== Doctor Notes =====
  RxList<Map<String, dynamic>> doctorNotes = <Map<String, dynamic>>[].obs;
  RxBool isDoctorNotesLoading = false.obs;
  RxBool isSendingNote = false.obs;

  // ===== Client Logged Data =====
  Rx<DateTime> clientLogSelectedDate = DateTime.now().obs;
  RxBool isClientLogLoading = false.obs;
  RxMap<String, dynamic> clientMealStats = <String, dynamic>{}.obs;
  RxMap<String, dynamic> clientWaterData = <String, dynamic>{}.obs;
  RxList<Map<String, dynamic>> clientMeals = <Map<String, dynamic>>[].obs;

  /// questions
  RxString report = ''.obs;

  TextEditingController currentEatingStyleOtherInfo = TextEditingController();
  TextEditingController allergiesIntolerancesOtherInfo =
      TextEditingController();
  TextEditingController foodsToAvoid = TextEditingController();
  TextEditingController waterIntake = TextEditingController();
  TextEditingController alcoholOrSmokingFrequency = TextEditingController();
  TextEditingController sleepStressSleepDuration = TextEditingController();
  TextEditingController medicationSupplementsDetails = TextEditingController();
  TextEditingController supplementsOther = TextEditingController();
  TextEditingController finalNotesConcerns = TextEditingController();

  RxList<DietOption> options = <DietOption>[
    DietOption(name: "Vegetarian", selected: false),
    DietOption(name: "Non-Vegetarian", selected: false),
    DietOption(name: "Vegan", selected: false),
    DietOption(name: "Eggetarian", selected: false),
    DietOption(name: "Jain", selected: false),
  ].obs;

  List<String> get selectedList =>
      options.where((e) => e.isSelected.value).map((e) => e.name).toList();

  // RxList<DietOption> allergies = <DietOption>[
  //   DietOption(name: "Gluten", selected: false),
  //   DietOption(name: "Lactose", selected: false),
  //   DietOption(name: "Nuts", selected: false),
  //   DietOption(name: "Eggs", selected: false),
  //   DietOption(name: "Seafood", selected: false),
  //   DietOption(name: "Soy", selected: false),
  // ].obs;

  // List<String> get selectedallergiesList =>
  //     allergies.where((e) => e.isSelected.value).map((e) => e.name).toList();

  // RxList<DietOption> dietaryHabits = <DietOption>[
  //   DietOption(name: "Vegetarian", selected: false),
  //   DietOption(name: "Non-Vegetarian", selected: false),
  //   DietOption(name: "Vegan", selected: false),
  //   DietOption(name: "Eggetarian", selected: false),
  //   DietOption(name: "Jain", selected: false),
  // ].obs;

  // List<String> get selectedDietaryHabitsList => dietaryHabits
  //     .where((e) => e.isSelected.value)
  //     .map((e) => e.name)
  //     .toList();

  /// Check if all 4 weeks have been assigned with non-zero calories
  bool get allWeeksAssigned {
    if (weeklyDietPlans.length < 4) return false;
    return weeklyDietPlans.every((w) => (w.totalCalories ?? 0) > 0);
  }

  /// Check if at least one week has been finalized (has non-zero calories)
  bool get hasFinalizedWeeks {
    return weeklyDietPlans.any((w) => (w.totalCalories ?? 0) > 0);
  }

  /// Count how many weeks still need to be assigned
  int get unassignedWeeksCount {
    if (weeklyDietPlans.length < 4) return 4 - weeklyDietPlans.length;
    return weeklyDietPlans.where((w) => (w.totalCalories ?? 0) == 0).length;
  }

  Map<String, Color> getColor(int backendWeek, int currentWeek) {
    Color containerColor;
    Color containerBorderColor;
    Color textColor;

    if (backendWeek < currentWeek) {
      // Past week - neutral/completed, no longer needs attention.
      containerColor = const Color(0xffF9FAFB);
      containerBorderColor = const Color(0xffE5E7EB);
      textColor = const Color(0xff6C737F);
    } else if (backendWeek == currentWeek) {
      // Active week - white card with a bold brand-color border so it
      // stands out as "this is the one happening right now".
      containerColor = const Color(0xffFFFFFF);
      containerBorderColor = const Color(0xff851653);
      textColor = const Color(0xff851653);
    } else {
      // Future week - soft pink, no border, reads as "coming up".
      containerColor = const Color(0xffFDF2FA);
      containerBorderColor = const Color(0xffFDF2FA);
      textColor = const Color(0xffEF45B2);
    }

    return {"bg": containerColor, "border": containerBorderColor, "text": textColor};
  }

  RxList<DietOption> allergiesOrIntolerances = <DietOption>[
    DietOption(name: "Gluten", selected: false),
    DietOption(name: "Dairy", selected: false),
    DietOption(name: "Nuts", selected: false),
    DietOption(name: "Eggs", selected: false),
    DietOption(name: "Seafood", selected: false),
    DietOption(name: "Soy", selected: false),
    DietOption(name: "Sesame", selected: false),
    DietOption(name: "Other", selected: false),
  ].obs;

  List<String> get selectedAllergiesOrIntolerancesList =>
      allergiesOrIntolerances
          .where((e) => e.isSelected.value)
          .map((e) => e.name)
          .toList();

  RxList<DietOption> cravings = <DietOption>[
    DietOption(name: "Sugar", selected: false),
    DietOption(name: "Salt", selected: false),
    DietOption(name: "Fried Foods", selected: false),
    DietOption(name: "Processed Snacks", selected: false),
  ].obs;

  List<String> get selectedcravingsList =>
      cravings.where((e) => e.isSelected.value).map((e) => e.name).toList();

  RxList<DietOption> cooksMeals = <DietOption>[
    DietOption(name: "Self", selected: false),
    DietOption(name: "Family", selected: false),
    DietOption(name: "Hired Help", selected: false),
    DietOption(name: "Eat Out / Food Delivery", selected: false),
  ].obs;

  List<String> get selectedCooksMealsList =>
      cooksMeals.where((e) => e.isSelected.value).map((e) => e.name).toList();

  RxList<DietOption> applyToYou = <DietOption>[
    DietOption(name: "PCOS / PCOD", selected: false),
    DietOption(name: "Hormonal Acne", selected: false),
    DietOption(name: "Irregular or Painful Periods", selected: false),
    DietOption(name: "Fibroids or Endometriosis", selected: false),
    DietOption(name: "Breastfeeding", selected: false),
    DietOption(name: "Currently Pregnant", selected: false),
    DietOption(name: "Menopausal / Perimenopausal", selected: false),
    DietOption(
      name: "History of Miscarriage or Fertility Issues",
      selected: false,
    ),
  ].obs;

  List<String> get selectedApplyToYouList =>
      applyToYou.where((e) => e.isSelected.value).map((e) => e.name).toList();

  RxList<DietOption> areYouOn = <DietOption>[
    DietOption(name: "Birth Control Pills", selected: false),
    DietOption(name: "Hormone Replacement Therapy (HRT)", selected: false),
    DietOption(name: "Fertility Treatments", selected: false),
  ].obs;

  List<String> get selectedAreYouOnList =>
      areYouOn.where((e) => e.isSelected.value).map((e) => e.name).toList();

  RxList<DietOption> digestionOrElimination = <DietOption>[
    DietOption(name: "Constipation", selected: false),
    DietOption(name: "Loose stools", selected: false),
    DietOption(name: "Gas/Bloating", selected: false),
    DietOption(name: "Acidity", selected: false),
    DietOption(name: "Indigestion", selected: false),
  ].obs;

  List<String> get selectedDigestionOREliminationList => digestionOrElimination
      .where((e) => e.isSelected.value)
      .map((e) => e.name)
      .toList();

  RxList<DietOption> supplements = <DietOption>[
    DietOption(name: "Multivitamins", selected: false),
    DietOption(name: "Protein Powders", selected: false),
    DietOption(name: "Omega-3", selected: false),
    DietOption(name: "Biotin/Collagen", selected: false),
    DietOption(name: "Ayurvedic/Herbal", selected: false),
    DietOption(name: "Other", selected: false),
  ].obs;

  List<String> get selectedSupplementsList =>
      supplements.where((e) => e.isSelected.value).map((e) => e.name).toList();

  RxList<SingleDietOption> alcohol = <SingleDietOption>[
    SingleDietOption(name: "Yes"),
    SingleDietOption(name: "No"),
  ].obs;

  // only 1 selected item
  RxString selectedAlcohol = "".obs;

  void selectItem(String name) {
    selectedAlcohol.value = name;
  }

  RxList<SingleDietOption> periods = <SingleDietOption>[
    SingleDietOption(name: "Yes"),
    SingleDietOption(name: "No"),
  ].obs;

  // only 1 selected item
  RxString selectedPeriods = "".obs;

  void selectPeriods(String name) {
    selectedPeriods.value = name;
  }

  RxList<SingleDietOption> frequencyOfBowel = <SingleDietOption>[
    SingleDietOption(name: "Daily"),
    SingleDietOption(name: "Irregular"),
  ].obs;

  // only 1 selected item
  RxString selectedFrequencyOfBowel = "".obs;

  void selectFrequencyOfBowel(String name) {
    selectedFrequencyOfBowel.value = name;
  }

  RxList<SingleDietOption> qualityOfSleep = <SingleDietOption>[
    SingleDietOption(name: "Restful"),
    SingleDietOption(name: "Interrupted"),
    SingleDietOption(name: "Insomnia"),
  ].obs;

  // only 1 selected item
  RxString selectedQualityOfSleep = "".obs;

  void selectQualityOfSleep(String name) {
    selectedQualityOfSleep.value = name;
  }

  RxList<SingleDietOption> stressLevel = <SingleDietOption>[
    SingleDietOption(name: "Low"),
    SingleDietOption(name: "Moderate"),
    SingleDietOption(name: "High"),
  ].obs;

  // only 1 selected item
  RxString selectedStressLevel = "".obs;

  void selectStressLevel(String name) {
    selectedStressLevel.value = name;
  }

  RxList<SingleDietOption> mentalHealthConditions = <SingleDietOption>[
    SingleDietOption(name: "Yes"),
    SingleDietOption(name: "No"),
  ].obs;

  // only 1 selected item
  RxString selectedMentalHealthConditions = "".obs;

  void selectMentalHealthConditionsl(String name) {
    selectedMentalHealthConditions.value = name;
  }

  RxList<SingleDietOption> prescribedMedication = <SingleDietOption>[
    SingleDietOption(name: "Yes"),
    SingleDietOption(name: "No"),
  ].obs;

  // only 1 selected item
  RxString selectedPrescribedMedication = "".obs;

  void selectPrescribedMedication(String name) {
    selectedPrescribedMedication.value = name;
  }

  Rx<XFile?> pickedReport = Rx<XFile?>(null);

  Future pickReport() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedReport.value = img;
    }
  }

  Rx<XFile?> pickedPaymentRecip = Rx<XFile?>(null);

  Future pickPaymentRecip() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      pickedPaymentRecip.value = img;
    }
  }

  RxList<SingleDietOption> personalizedNutrition = <SingleDietOption>[
    SingleDietOption(name: "Yes"),
    SingleDietOption(name: "Maybe"),
    SingleDietOption(name: "Not yet"),
  ].obs;

  // only 1 selected item
  RxString selectedPersonalizedNutrition = "".obs;

  void selectPersonalizedNutrition(String name) {
    selectedPersonalizedNutrition.value = name;
  }

  // ── Custom consultation form (configured by doctor in Performance) ──
  // Template fields fetched from /consultation-form
  RxList<ConsultationFormField> consultationTemplate =
      <ConsultationFormField>[].obs;
  RxBool isConsultationTemplateLoading = false.obs;
  // Answers keyed by fieldId. Value type depends on field type:
  //   text/textarea/number/date/singleChoice/yesNo -> String
  //   multiChoice -> List<String>
  final RxMap<String, dynamic> customAnswerValues = <String, dynamic>{}.obs;
  // Backing TextEditingControllers for text-style fields, keyed by fieldId.
  final Map<String, TextEditingController> _customTextControllers = {};

  final ConsultationFormService _consultationFormService =
      ConsultationFormService();

  Future<void> fetchConsultationTemplate() async {
    isConsultationTemplateLoading.value = true;
    try {
      final fields = await _consultationFormService.getMyTemplate();
      consultationTemplate.value = fields;
      _ensureAnswerStateForTemplate();
    } finally {
      isConsultationTemplateLoading.value = false;
    }
  }

  /// Make sure every templated field has an entry in [customAnswerValues] and
  /// (where applicable) a [TextEditingController]. Existing values are
  /// preserved so prefill from server is not wiped out.
  void _ensureAnswerStateForTemplate() {
    final keepIds = consultationTemplate.map((f) => f.fieldId).toSet();
    customAnswerValues.removeWhere((k, _) => !keepIds.contains(k));
    _customTextControllers.removeWhere((k, c) {
      if (!keepIds.contains(k)) {
        c.dispose();
        return true;
      }
      return false;
    });

    for (final f in consultationTemplate) {
      final isTextual =
          f.type == ConsultationFieldType.text ||
          f.type == ConsultationFieldType.textarea ||
          f.type == ConsultationFieldType.number ||
          f.type == ConsultationFieldType.date;
      if (isTextual) {
        final existing = _customTextControllers[f.fieldId];
        final initial = (customAnswerValues[f.fieldId] ?? '').toString();
        if (existing == null) {
          _customTextControllers[f.fieldId] = TextEditingController(
            text: initial,
          );
        } else if (existing.text != initial) {
          existing.text = initial;
        }
      }
      if (f.type == ConsultationFieldType.multiChoice) {
        final cur = customAnswerValues[f.fieldId];
        if (cur is! List) {
          customAnswerValues[f.fieldId] = <String>[];
        }
      }
    }
  }

  TextEditingController customTextControllerFor(String fieldId) {
    return _customTextControllers.putIfAbsent(
      fieldId,
      () => TextEditingController(
        text: (customAnswerValues[fieldId] ?? '').toString(),
      ),
    );
  }

  void setCustomAnswer(String fieldId, dynamic value) {
    customAnswerValues[fieldId] = value;
  }

  void toggleMultiChoiceAnswer(String fieldId, String option) {
    final current = customAnswerValues[fieldId];
    final list = (current is List)
        ? List<String>.from(current.map((e) => e.toString()))
        : <String>[];
    if (list.contains(option)) {
      list.remove(option);
    } else {
      list.add(option);
    }
    customAnswerValues[fieldId] = list;
  }

  static const _consentFieldIds = {
    'consent_acknowledgement',
    'consent_signature_name',
  };

  /// Build the `customAnswers` payload sent inside the first-consultation form.
  List<Map<String, dynamic>> _buildCustomAnswersPayload() {
    final result = <Map<String, dynamic>>[];
    for (final f in consultationTemplate) {
      // Consent & Confidentiality is the patient's to fill in, not the
      // dietician's - never include it in a dietician save (the backend
      // strips it too, but excluding it here also means saving doesn't
      // submit stale/locked values back as if the dietician had "answered"
      // them).
      if (_consentFieldIds.contains(f.fieldId)) continue;
      dynamic value;
      switch (f.type) {
        case ConsultationFieldType.text:
        case ConsultationFieldType.textarea:
        case ConsultationFieldType.number:
        case ConsultationFieldType.date:
          value = _customTextControllers[f.fieldId]?.text.trim() ?? '';
          break;
        case ConsultationFieldType.yesNo:
        case ConsultationFieldType.singleChoice:
          value = (customAnswerValues[f.fieldId] ?? '').toString();
          break;
        case ConsultationFieldType.multiChoice:
          final raw = customAnswerValues[f.fieldId];
          value = raw is List
              ? List<String>.from(raw.map((e) => e.toString()))
              : <String>[];
          break;
        case ConsultationFieldType.file:
          // Lives in labReports.files via the separate pickedReport
          // multipart upload, not in customAnswers.
          continue;
      }
      result.add({
        'fieldId': f.fieldId,
        'label': f.label,
        'type': f.type.apiValue,
        'value': value,
      });
    }
    return result;
  }

  void clearCustomAnswers() {
    customAnswerValues.clear();
    for (final c in _customTextControllers.values) {
      c.dispose();
    }
    _customTextControllers.clear();
  }

  /// Whether [field] should be shown to the dietician right now, given the
  /// patient's gender and the current in-progress answers (for
  /// dependsOnFieldId conditional follow-ups, e.g. "If Other, specify").
  bool isFieldVisible(ConsultationFormField field, String patientGender) {
    final scopeOk = switch (field.genderScope) {
      'female' => patientGender == 'Female',
      'male' => patientGender == 'Male',
      _ => true,
    };
    if (!scopeOk) return false;
    if (field.dependsOnFieldId == null) return true;
    return _dependencyMet(field);
  }

  bool _dependencyMet(ConsultationFormField field) {
    final parentAnswer = customAnswerValues[field.dependsOnFieldId];
    if (parentAnswer is List) {
      return parentAnswer.any(
        (v) => field.dependsOnValues.contains(v.toString()),
      );
    }
    return field.dependsOnValues.contains((parentAnswer ?? '').toString());
  }

  // api functions
  Future<void> getPatientProfile(String patientId) async {
    isProfileLoading.value = true;
    try {
      final response = await service.getPatientProfile(patientId);

      if (response != null) {
        patientProfileModel.value = PatientProfileModel.fromJson(
          response['data'],
        );
        weeklyDietPlans.value =
            (response['data']['weeklyDietPlans'] as List? ?? [])
                .map((e) => WeeklyDietPlan.fromJson(e as Map<String, dynamic>))
                .toList();
        // Sync deactivation toggle with backend
        isProfileDeactivated.value =
            patientProfileModel.value?.status?.isActive == false;
      }
    } catch (e) {
      debugPrint('-------------$e');
    }
    isProfileLoading.value = false;
  }

  Future<void> togglePatientActive(String patientId) async {
    final newIsActive = isProfileDeactivated
        .value; // toggling: deactivated means isActive=true now
    isProfileDeactivated.value = !isProfileDeactivated.value;
    final response = await service.togglePatientActive(patientId, newIsActive);
    if (response != null) {
      // Refresh profile to get updated status
      await getPatientProfile(patientId);
      // Refresh patient lists so the change shows everywhere
      fetchOngoingPatients();
    } else {
      // Revert on failure
      isProfileDeactivated.value = !isProfileDeactivated.value;
      Get.snackbar(
        'Error',
        'Failed to update patient status',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Permanently deletes a patient (irreversible - see the confirmation
  /// dialog in patient_profile_view.dart, which requires re-typing the
  /// patient's email before this is ever called). Returns true/false
  /// so the caller can navigate away and show a snackbar; on failure the
  /// backend's specific message (e.g. an email mismatch, caught even
  /// though the dialog already checks it client-side) is shown instead of
  /// a generic error.
  Future<bool> deletePatient(String patientId, String confirmEmail) async {
    final data = await service.deletePatient(patientId, confirmEmail);
    if (data != null && data['success'] == true) {
      // Refresh every tab so the deleted patient disappears everywhere,
      // regardless of which tab they were in (ongoing/new/past).
      fetchOngoingPatients();
      fetchNewPatients();
      fetchPastPatients();
      return true;
    }
    Get.snackbar(
      'Error',
      data?['message'] ?? 'Failed to delete patient',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /// Fetch tracking data (calorie intake, weight trend, BMI) for charts
  Future<void> fetchTrackingData(String patientId, String period) async {
    isTrackingLoading.value = true;
    try {
      final response = await service.getPatientTrackingData(patientId, period);
      if (response != null && response['data'] != null) {
        trackingData.value = TrackingData.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('fetchTrackingData error: $e');
    }
    isTrackingLoading.value = false;
  }

  /// Change the unified time period for all charts and refetch
  void changeTrackingPeriod(String patientId, String period) {
    trackingTimePeriod.value = period;
    fetchTrackingData(patientId, period);
  }

  // ===== Journey Image Methods =====

  /// Fetch auto-generated milestone journey cards from body log images
  Future<void> fetchAutoJourneyMilestones(String patientId) async {
    isAutoMilestonesLoaded.value = false;
    try {
      final response = await service.getPatientJourneyMilestones(patientId);
      debugPrint(
        '📸 fetchAutoJourneyMilestones response: ${response != null ? 'OK' : 'NULL'}',
      );
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final List milestones = data['milestones'] ?? [];
        final List manual = data['manualImages'] ?? [];
        debugPrint(
          '📸 milestones: ${milestones.length}, manual: ${manual.length}',
        );

        final List<JourneyImageModel>
        cards = milestones.map<JourneyImageModel>((m) {
          debugPrint(
            '📸 milestone ${m['dayLabel']}: beforeImageUrl=${(m['beforeImageUrl'] ?? '').toString().length > 20 ? 'YES' : 'EMPTY'}',
          );
          return JourneyImageModel(
            id: 'auto_${m['dayNumber']}',
            patientId: patientId,
            dieticianId: '',
            uploadedBy: '',
            uploadedByRole: 'auto',
            beforeImageUrl: m['beforeImageUrl'] ?? '',
            afterImageUrl: m['afterImageUrl'] ?? '',
            description: m['description'] ?? '',
            dayLabel: m['dayLabel'] ?? 'Day 1',
            createdAt: m['date'] != null
                ? DateTime.parse(m['date'].toString())
                : DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();

        // Append any manual journey images
        for (final m in manual) {
          cards.add(JourneyImageModel.fromJson(m));
        }

        debugPrint('📸 Setting autoJourneyCards with ${cards.length} cards');
        autoJourneyCards.assignAll(cards);
      }
    } catch (e) {
      debugPrint('fetchAutoJourneyMilestones error: $e');
    }
    isAutoMilestonesLoaded.value = true;
  }

  /// Fetch all journey images for a patient
  Future<void> fetchJourneyImages(String patientId) async {
    isJourneyLoading.value = true;
    try {
      final response = await service.getPatientJourneyImages(patientId);
      if (response != null && response['success'] == true) {
        final List data = response['data'] ?? [];
        journeyImages.value = data
            .map((e) => JourneyImageModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchJourneyImages error: $e');
    }
    isJourneyLoading.value = false;
  }

  /// Upload journey images for a patient
  Future<bool> uploadJourneyImage(
    String patientId, {
    String? beforeImagePath,
    String? afterImagePath,
    String description = '',
    String dayLabel = 'Day 1',
  }) async {
    isJourneyUploading.value = true;
    try {
      final map = <String, dynamic>{
        'description': description,
        'dayLabel': dayLabel,
      };
      if (beforeImagePath != null) {
        map['beforeImage'] = await dio.MultipartFile.fromFile(beforeImagePath);
      }
      if (afterImagePath != null) {
        map['afterImage'] = await dio.MultipartFile.fromFile(afterImagePath);
      }
      final formData = dio.FormData.fromMap(map);

      final response = await service.uploadJourneyImage(patientId, formData);
      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Success',
          'Journey image uploaded!',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchJourneyImages(patientId);
        isJourneyUploading.value = false;
        return true;
      }
    } catch (e) {
      debugPrint('uploadJourneyImage error: $e');
    }
    isJourneyUploading.value = false;
    Get.snackbar(
      'Error',
      'Failed to upload image',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /// Update a journey image entry
  Future<bool> updateJourneyImage(
    String patientId,
    String imageId, {
    String? beforeImagePath,
    String? afterImagePath,
    String? description,
    String? dayLabel,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (description != null) map['description'] = description;
      if (dayLabel != null) map['dayLabel'] = dayLabel;
      if (beforeImagePath != null) {
        map['beforeImage'] = await dio.MultipartFile.fromFile(beforeImagePath);
      }
      if (afterImagePath != null) {
        map['afterImage'] = await dio.MultipartFile.fromFile(afterImagePath);
      }
      final formData = dio.FormData.fromMap(map);

      final response = await service.updateJourneyImage(
        patientId,
        imageId,
        formData,
      );
      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Success',
          'Journey image updated!',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchJourneyImages(patientId);
        return true;
      }
    } catch (e) {
      debugPrint('updateJourneyImage error: $e');
    }
    Get.snackbar(
      'Error',
      'Failed to update',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  /// Delete a journey image
  Future<bool> deleteJourneyImage(String patientId, String imageId) async {
    try {
      final response = await service.deleteJourneyImage(patientId, imageId);
      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Success',
          'Journey image deleted',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchJourneyImages(patientId);
        return true;
      }
    } catch (e) {
      debugPrint('deleteJourneyImage error: $e');
    }
    return false;
  }

  /// Silent refresh patient profile without loading indicator
  Future<void> silentRefreshPatientProfile(String patientId) async {
    try {
      final response = await service.getPatientProfile(patientId);

      if (response != null) {
        final newProfile = PatientProfileModel.fromJson(response['data']);
        final newWeekly = (response['data']['weeklyDietPlans'] as List? ?? [])
            .map((e) => WeeklyDietPlan.fromJson(e as Map<String, dynamic>))
            .toList();

        // Detect week-level changes too (e.g. a week being finalized with
        // non-zero calories). Without this, the UI stays stuck on the
        // "Create Diet Plan" button after finalizing, until a tracked
        // status field happens to change.
        final oldFinalizedCount = weeklyDietPlans
            .where((w) => (w.totalCalories ?? 0) > 0)
            .length;
        final newFinalizedCount = newWeekly
            .where((w) => (w.totalCalories ?? 0) > 0)
            .length;

        final statusChanged =
            patientProfileModel.value?.status?.requestStatus !=
                newProfile.status?.requestStatus ||
            patientProfileModel.value?.status?.hasPaymentUpdate !=
                newProfile.status?.hasPaymentUpdate ||
            patientProfileModel.value?.status?.activeDietPlanId !=
                newProfile.status?.activeDietPlanId;

        // Detect calorie deltas inside already-existing week entries (e.g. a
        // week's diet plan was just replaced with a different one).
        bool calorieDelta = false;
        for (final nw in newWeekly) {
          final matches = weeklyDietPlans.where((w) => w.week == nw.week);
          final old = matches.isEmpty ? null : matches.first;
          if (old == null ||
              (old.totalCalories ?? 0) != (nw.totalCalories ?? 0)) {
            calorieDelta = true;
            break;
          }
        }

        if (statusChanged ||
            oldFinalizedCount != newFinalizedCount ||
            weeklyDietPlans.length != newWeekly.length ||
            calorieDelta) {
          patientProfileModel.value = newProfile;
          weeklyDietPlans.value = newWeekly;
          debugPrint('📡 Patient profile updated silently');
        }
      }
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  /// Fetch ongoing patients (Paid + Active plan)
  Future<void> fetchOngoingPatients() async {
    isOngoingLoading.value = true;
    try {
      final response = await service.getPatientsByTab(tab: 'ongoing');
      if (response != null && response['data'] != null) {
        ongoingPatients.value = (response['data'] as List)
            .map((e) => OngoingPatientModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchOngoingPatients error: $e');
    }
    isOngoingLoading.value = false;
  }

  /// Fetch new patients (Unpaid, no active plan)
  Future<void> fetchNewPatients() async {
    isNewLoading.value = true;
    try {
      final response = await service.getPatientsByTab(tab: 'new');
      if (response != null && response['data'] != null) {
        newPatients.value = (response['data'] as List)
            .map((e) => NewPatientModel.fromJson(e))
            .toList()
            .reversed
            .toList();
      }
    } catch (e) {
      debugPrint('fetchNewPatients error: $e');
    }
    isNewLoading.value = false;
  }

  /// Fetch past patients (Completed)
  Future<void> fetchPastPatients() async {
    isPastLoading.value = true;
    try {
      final response = await service.getPatientsByTab(tab: 'past');
      if (response != null && response['data'] != null) {
        pastPatients.value = (response['data'] as List)
            .map((e) => PastPatientModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchPastPatients error: $e');
    }
    isPastLoading.value = false;
  }

  /// Load all patient lists
  Future<void> loadAllPatientLists() async {
    await Future.wait([
      fetchOngoingPatients(),
      fetchNewPatients(),
      fetchPastPatients(),
    ]);
  }

  /// Filtered ongoing patients based on search query
  List<OngoingPatientModel> get filteredOngoingPatients {
    if (searchQuery.value.isEmpty) return ongoingPatients;
    return ongoingPatients
        .where(
          (p) =>
              p.fullName?.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  /// Filtered new patients based on search query
  List<NewPatientModel> get filteredNewPatients {
    if (searchQuery.value.isEmpty) return newPatients;
    return newPatients
        .where(
          (p) =>
              p.fullName?.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  /// Filtered past patients based on search query
  List<PastPatientModel> get filteredPastPatients {
    if (searchQuery.value.isEmpty) return pastPatients;
    return pastPatients
        .where(
          (p) =>
              p.fullName?.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  // Future<void> sendConsultation(String patientId, bool isFemale) async {
  //   isConsultationSending.value = true;

  //   // Prepare JSON part
  //   final rawData = {
  //     "dietaryHabitsAllergies": {
  //       "currentEatingStyle": {
  //         "options": selectedList,
  //         "otherInfo": currentEatingStyleOtherInfo.text,
  //       },
  //       "allergiesIntolerances": {
  //         "options": selectedAllergiesOrIntolerancesList,
  //         "otherInfo": allergiesIntolerancesOtherInfo.text,
  //       },
  //       "foodsToAvoid": {"text": foodsToAvoid.text},
  //       "cravings": {"options": selectedcravingsList},
  //       "whoCooksMeals": {"options": selectedCooksMealsList},
  //       "waterIntake": waterIntake.text,
  //       "alcoholOrSmoking": {
  //         "uses": selectedAlcohol.value,
  //         "frequency": alcoholOrSmokingFrequency.text,
  //       },
  //     },

  //     "femaleSpecificHealth": {
  //       "isApplicable": isFemale,
  //       "periodsRegular": selectedPeriods.value,
  //       "issues": selectedApplyToYouList,
  //       "onMedications": selectedAreYouOnList,
  //     },

  //     "digestionElimination": {
  //       "symptoms": selectedDigestionOREliminationList,
  //       "bowelFrequency": selectedFrequencyOfBowel.value,
  //     },

  //     "sleepStress": {
  //       "sleepDuration": sleepStressSleepDuration.text,
  //       "sleepQuality": [selectedQualityOfSleep.value],
  //       "stressLevel": selectedStressLevel.value,
  //       "mentalHealthCondition": selectedMentalHealthConditions.value,
  //       "mentalHealthNotes": "",
  //     },

  //     "medicationSupplements": {
  //       "onMedication": {
  //         "answer": selectedPrescribedMedication.value,
  //         "details": medicationSupplementsDetails.text,
  //       },
  //       "supplements": {
  //         "options": selectedSupplementsList,
  //         "other": supplementsOther.text,
  //       },
  //     },

  //     "finalNotes": {
  //       "concerns": finalNotesConcerns.text,
  //       "readinessToCommit": selectedPersonalizedNutrition.value,
  //     },
  //   };

  //   // JSON encode
  //   final jsonString = jsonEncode(rawData);

  //   // FILE
  //   dio.MultipartFile? file;
  //   if (pickedReport.value != null) {
  //     file = await dio.MultipartFile.fromFile(
  //       pickedReport.value!.path,
  //       filename: pickedReport.value!.name,
  //     );
  //   }

  //   // FORM DATA
  //   final formData = dio.FormData.fromMap({
  //     "data": jsonString,
  //     "files": file != null ? [file] : [],
  //   });

  //   log("---- FINAL SEND BODY ---- $formData");

  //   try {
  //     final response = await service.sendConsultation(formData, patientId);

  //     if (response != null) {
  //       log('--------> $response');

  //       String? firstConsultationId = response['data']?['_id'];

  //       patientProfileModel.value?.status?.firstConsultationId =
  //           firstConsultationId;
  //       patientProfileModel.refresh();
  //       Get.back();
  //     }
  //   } catch (e) {
  //     debugPrint('-------------$e');
  //   }

  //   isConsultationSending.value = false;
  // }
  Future<void> sendConsultation(String patientId, bool isFemale) async {
    isConsultationSending.value = true;

    // --------------------------
    // 1. Prepare metadata (JSON)
    // --------------------------
    final rawData = {
      "dietaryHabitsAllergies": {
        "currentEatingStyle": {
          "options": selectedList, // ["Vegetarian", "Jain"]
          "otherInfo": currentEatingStyleOtherInfo.text,
        },
        "allergiesIntolerances": {
          "options": selectedAllergiesOrIntolerancesList,
          "otherInfo": allergiesIntolerancesOtherInfo.text,
        },
        "foodsToAvoid": {"text": foodsToAvoid.text},
        "cravings": {"options": selectedcravingsList},
        "whoCooksMeals": {"options": selectedCooksMealsList},
        "waterIntake": waterIntake.text,
        "alcoholOrSmoking": {
          "uses": selectedAlcohol.value,
          "frequency": alcoholOrSmokingFrequency.text,
        },
      },
      "femaleSpecificHealth": {
        "isApplicable": isFemale,
        "periodsRegular": selectedPeriods.value,
        "issues": selectedApplyToYouList,
        "onMedications": selectedAreYouOnList,
      },
      "digestionElimination": {
        "symptoms": selectedDigestionOREliminationList,
        "bowelFrequency": selectedFrequencyOfBowel.value,
      },
      "sleepStress": {
        "sleepDuration": sleepStressSleepDuration.text,
        "sleepQuality": [selectedQualityOfSleep.value],
        "stressLevel": selectedStressLevel.value,
        "mentalHealthCondition": selectedMentalHealthConditions.value,
        "mentalHealthNotes": "",
      },
      "medicationSupplements": {
        "onMedication": {
          "answer": selectedPrescribedMedication.value,
          "details": medicationSupplementsDetails.text,
        },
        "supplements": {
          "options": selectedSupplementsList,
          "other": supplementsOther.text,
        },
      },
      "labReports": {}, // Keep empty, server will populate
      "finalNotes": {
        "concerns": finalNotesConcerns.text,
        "readinessToCommit": selectedPersonalizedNutrition.value,
      },
      "customAnswers": _buildCustomAnswersPayload(),
    };

    final jsonString = jsonEncode(rawData);
    log("---- FINAL JSON ----\n$jsonString");

    // --------------------------
    // 2. Prepare file
    // --------------------------
    dio.MultipartFile? reportFile;
    if (pickedReport.value != null) {
      reportFile = await dio.MultipartFile.fromFile(
        pickedReport.value!.path,
        filename: pickedReport.value!.name,
      );
    }

    // --------------------------
    // 3. Create FormData
    // --------------------------
    final formData = dio.FormData();
    formData.fields.add(MapEntry("data", jsonString));

    if (reportFile != null) {
      formData.files.add(MapEntry("file", reportFile));
    }

    // --------------------------
    // 4. Send request
    // --------------------------
    try {
      final response = await service.sendConsultation(formData, patientId);

      if (response != null) {
        log("---> Response: $response");

        // Re-fetch the full profile rather than patching firstConsultationId
        // locally - editing an already-consented consultation resets
        // status.patientConsented server-side (the patient must re-consent),
        // and that's what gates the "Create Diet Plan" button.
        await getPatientProfile(patientId);
        Get.back();
      }
    } catch (e) {
      debugPrint("---- Upload error ---- $e");
    }

    isConsultationSending.value = false;
  }

  /// Returns the newly-created diet plan's id (or null on failure) so the
  /// caller can use it directly for the immediate follow-up fetch, rather
  /// than reading it back via `patientProfileModel.value?.status?.
  /// activeDietPlanId` - that chain is an optional-chained *write* below,
  /// which silently no-ops if patientProfileModel.value or .status happens
  /// to be null at this point (e.g. profile not yet loaded), leaving the
  /// caller to fetch with an empty dietPlanId and show a blank/zeroed plan
  /// even though generation actually succeeded.
  Future<String?> generateDietPlan(
    String patientId,
    String firstConsultationId,
    String requestId, {
    DateTime? startDate,
    double? currentWeight,
  }) async {
    generateDietPlanLoading.value = true;
    final data = {
      'firstConsultationId': firstConsultationId,
      'requestId': requestId,
      'calorieStrategy': selectedCalorieStrategy,
      'macroStrategy': selectedMacroStrategy,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (currentWeight != null) 'currentWeight': currentWeight,
    };
    String? dietPlanId;
    try {
      final response = await service.generateDietPlan(data, patientId);
      if (response != null) {
        debugPrint('-----------------${response['success']}');

        if (response['success'] == true) {
          showGenerateDietPlanSheet.value = true;

          dietPlanId = response['data']?['dietPlanId'];
          patientProfileModel.value?.status?.activeDietPlanId = dietPlanId;

          patientProfileModel.refresh();
        }
      }
    } catch (e) {
      debugPrint('-----------------$e');
    }
    generateDietPlanLoading.value = false;
    return dietPlanId;
  }

  /// Generates (or regenerates) specific week(s) of an already-created diet
  /// plan - the dietician-initiated cadence for Golden (weeks 3-4) and
  /// Platinum (one week at a time) tiers. Returns the raw response so the
  /// caller can surface a tier-gating/validation message on failure, unlike
  /// generateDietPlan above which only logs it.
  Future<Map<String, dynamic>?> regenerateWeek(
    String patientId,
    String dietPlanId,
    List<int> weekNumbers, {
    double? currentWeight,
  }) async {
    generateDietPlanLoading.value = true;
    final data = {
      'weekNumbers': weekNumbers,
      'calorieStrategy': selectedCalorieStrategy,
      'macroStrategy': selectedMacroStrategy,
      if (currentWeight != null) 'currentWeight': currentWeight,
    };
    Map<String, dynamic>? response;
    try {
      response = await service.generateWeek(data, patientId, dietPlanId);
      if (response != null && response['success'] == true) {
        showGenerateDietPlanSheet.value = true;
        await getPatientProfile(patientId);
      }
    } catch (e) {
      debugPrint('-----------------$e');
    }
    generateDietPlanLoading.value = false;
    return response;
  }

  Future<void> getAiGeneratedDietPlan(
    String patientId,
    String dietPlanId,
  ) async {
    generateDietPlanLoading.value = true;

    try {
      final response = await service.getAiGeneratedDietPlan(
        patientId,
        dietPlanId,
      );

      if (response != null) {
        DietPlanData data = DietPlanData.fromJson(response["data"]);
        dietPlanData.value = data;

        // default select Week 1
        selectedWeek.value = "Week 1";

        debugPrint("Default week loaded: Week 1");
        updateSelectedWeekData(1);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    generateDietPlanLoading.value = false;
  }

  void setDietPlanData(DietPlanData data) {
    dietPlanData.value = data;
    // default selections
    selectedWeek.value = "Week 1";
    updateSelectedWeekData(1);
    updateShiftMeals(selectedShift.value);
  }

  /// Loads the full recipe-options pool for one week of a not-yet-finalized
  /// (Draft) diet plan - the data source for select_diet_sheet.dart. Unlike
  /// getAiGeneratedDietPlan (which loads all 4 weeks' single AI-picked
  /// recipe per slot in one call), this endpoint is week-scoped and returns
  /// every eligible recipe per slot, so it's called once for whichever
  /// single week that screen is reviewing.
  Future<void> getDraftDietOptions(
    String patientId,
    String dietPlanId,
    int week,
  ) async {
    generateDietPlanLoading.value = true;
    // Fresh screen load - don't carry over a previous patient/plan's
    // expanded-options or day-group tab state onto this one.
    expandedShifts.clear();
    selectedDayGroup.value = 'Monday';

    try {
      final response = await service.getDraftWeekOptions(
        patientId,
        dietPlanId,
        week,
      );

      if (response != null) {
        final data = DietPlanWeekData.fromJson(response["data"]);
        draftDietOptions.value = data;
        selectedWeek.value = "Week $week";
        _applyDraftOptionsForWeek(week);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    generateDietPlanLoading.value = false;
  }

  /// Seeds weekSelectedRecipes with whichever recipes the backend already
  /// flagged isSelected (the AI's own picks) and refreshes the current
  /// tab's options list - this is what makes the Total Budget non-zero by
  /// default, matching "the calorie selection already done" instead of
  /// requiring the dietician to manually re-tap every card.
  void _applyDraftOptionsForWeek(int weekNumber) {
    final data = draftDietOptions.value;
    if (data == null) return;

    final defaultSelected = <Recipe>[];
    for (final dayGroupOptions in data.dayGroups) {
      for (final st in dayGroupOptions.servingTimes) {
        // The Supplements pseudo-slot is a browsing convenience only - any
        // already-selected supplement it shows also appears (and gets
        // processed) under its own real slot, so skip it here to avoid
        // double-counting the same selection twice.
        if (st.servingTime == 'Supplements') continue;
        for (final r in st.recipes) {
          if (!r.isSelected) continue;
          final recipe = _recipeFromOptionModel(
            r,
            st.servingTime,
            dayGroupOptions.dayGroup,
          );
          defaultSelected.add(recipe);
          // A backend `servings` of exactly 1 means "never explicitly set"
          // (see cleanSelectedMeals' default) for any unit - not a genuine
          // "1 gram" or "exactly 1 piece" - so seed from the trend-aware
          // default instead. Piece-based items need this too now: a
          // weight-loss default is 1/4, not 1, so "1" can no longer be
          // trusted as the piece baseline the way it was before this phase.
          // Only applies to a not-yet-finalized week though - once
          // data.isFinalized is true, `servings` came from the dietician's
          // actual finalizeWeekPlan save (see getDraftWeekOptions' finalized-
          // Plan preference), so an explicit "1" must be trusted as-is or
          // "Update Diet Plan" would silently reset it back to the trend
          // default on every re-open.
          final isUnexplicitDefault = r.servings == 1 && !data.isFinalized;
          selectedServings[servingsKey(recipe)] = isUnexplicitDefault
              ? _defaultServingsForTrend(recipe)
              : r.servings;
          if (recipe.hasSecondaryComponent) {
            final isUnexplicitSecondaryDefault =
                r.secondaryServings == 1 && !data.isFinalized;
            selectedSecondaryServings[servingsKey(
              recipe,
            )] = isUnexplicitSecondaryDefault
                ? recipe.secondaryBaseQuantity
                : r.secondaryServings;
          }
        }
      }
    }
    weekSelectedRecipes[weekNumber] = defaultSelected;

    updateShiftOptions(selectedShift.value);
    calculateTotalsForWeek(weekNumber);
  }

  /// Switches which day-group tab is active - purely a client-side filter
  /// over the already-fetched data.dayGroups (all 4 groups were bundled
  /// into one response), so no re-fetch is needed and in-progress
  /// selections in other groups are never lost.
  void updateSelectedDayGroup(String dayGroup) {
    selectedDayGroup.value = dayGroup;
    updateShiftOptions(selectedShift.value);
    final currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);
    calculateTotalsForWeek(currentWeekNumber);
  }

  /// Set the current tab's shift and refresh its full options list (the
  /// draft-review screen's counterpart to updateShiftMeals) - scoped to
  /// whichever day-group is currently selected.
  void updateShiftOptions(String shift) {
    selectedShift.value = shift;
    final data = draftDietOptions.value;
    if (data == null) {
      shiftOptions.value = [];
      return;
    }
    final dayGroupOptions = data.dayGroups.firstWhere(
      (g) => g.dayGroup == selectedDayGroup.value,
      orElse: () =>
          DayGroupOptions(dayGroup: selectedDayGroup.value, servingTimes: []),
    );
    final match = dayGroupOptions.servingTimes.firstWhere(
      (s) => s.servingTime == shift,
      orElse: () =>
          ServingTimeModel(servingTime: '', selectedRecipeId: '', recipes: []),
    );
    shiftOptions.value = match.recipes
        .map((r) => _recipeFromOptionModel(r, shift, selectedDayGroup.value))
        .toList();
  }

  void toggleShowMoreOptions(String shift) {
    if (expandedShifts.contains(shift)) {
      expandedShifts.remove(shift);
    } else {
      expandedShifts.add(shift);
    }
  }

  /// Selected recipes first, then unselected ones ranked by how close their
  /// calories are to the selected recipes' average - "almost similar",
  /// matching what a dietician would consider a natural swap. Once expanded
  /// the full pool renders in this same order, so scrolling further
  /// naturally surfaces the more calorie-different (more varied) options.
  List<Recipe> _sortedOptions(
    List<Recipe> options,
    List<Recipe> selectedForWeek,
  ) {
    final selected = options.where(selectedForWeek.contains).toList();
    final unselected = options
        .where((r) => !selectedForWeek.contains(r))
        .toList();
    if (selected.isNotEmpty) {
      final avgCalories =
          selected.map((r) => r.nutrition.calories).reduce((a, b) => a + b) /
          selected.length;
      unselected.sort(
        (a, b) => (a.nutrition.calories - avgCalories).abs().compareTo(
          (b.nutrition.calories - avgCalories).abs(),
        ),
      );
    }
    return [...selected, ...unselected];
  }

  /// The cards actually shown for a shift: every selection plus a small
  /// preview of similar alternatives, unless the dietician has expanded
  /// this slot to see the full pool.
  List<Recipe> visibleShiftOptions(
    List<Recipe> options,
    List<Recipe> selectedForWeek,
    String shift,
  ) {
    final sorted = _sortedOptions(options, selectedForWeek);
    if (expandedShifts.contains(shift)) return sorted;
    final selectedCount = options.where(selectedForWeek.contains).length;
    return sorted.take(selectedCount + _previewAlternativesCount).toList();
  }

  /// How many unselected alternatives are hidden behind "show more" for this
  /// shift - 0 once expanded (nothing left to reveal) or if the pool is
  /// already small enough to show in full.
  int extraOptionsCount(List<Recipe> options, List<Recipe> selectedForWeek) {
    final selectedCount = options.where(selectedForWeek.contains).length;
    final unselectedCount = options.length - selectedCount;
    return (unselectedCount - _previewAlternativesCount).clamp(
      0,
      unselectedCount,
    );
  }

  /// Adapts a RecipeModel (the options-pool shape, models/update_ai_diet_
  /// plain_model.dart) into a Recipe (models/ai_diet_plain_model.dart) so
  /// the existing weekSelectedRecipes/toggleMealSelection/
  /// calculateTotalsForWeek/buildFinalizeWeekPayload machinery - already
  /// built around Recipe and unrelated to this feature - keeps working
  /// unchanged. baseServingQuantity/servingUnit carry the recipe's own
  /// serving size (e.g. Chole=350g, Chapati=1 piece) forward so the
  /// servings stepper has a "1x" reference point to scale from.
  ///
  /// [slotServingTime] is the tab/slot this recipe was picked FOR, not
  /// necessarily its own native servingTime - a side/salad cross-listed
  /// into e.g. Dinner (see utils/dietPlanOptions.js's broadening) still
  /// natively stores servingTime:'Lunch', but must be finalized under
  /// Dinner if that's the tab the dietician selected it from.
  ///
  /// "Supplements" is a browsing-only pseudo-tab (see buildServingTimeOptions
  /// in dietPlanOptions.js) - a supplement picked from it must still persist
  /// under its own real servingTime (e.g. "Night Drink"), never under the
  /// literal string "Supplements", which finalizeWeekPlan would reject.
  ///
  /// [dayGroup] is which of the 4 day-groups (Monday/Tuesday/Wednesday/
  /// Thursday) this recipe was picked for - see dayGroups.js.
  Recipe _recipeFromOptionModel(
    RecipeModel m,
    String slotServingTime,
    String dayGroup,
  ) {
    final persistedServingTime = slotServingTime == 'Supplements'
        ? (m.servingTime.isNotEmpty ? m.servingTime : slotServingTime)
        : slotServingTime;
    return Recipe(
      id: m.id,
      name: m.name,
      image: m.image,
      totalWeightGrams: m.servingSize.quantity.round(),
      nutrition: Nutrition(
        calories: m.nutrition.calories,
        protein: m.nutrition.protein,
        carbs: m.nutrition.carbs,
        fats: m.nutrition.fats,
        fiber: m.nutrition.fiber,
      ),
      baseServingQuantity: m.servingSize.quantity > 0
          ? m.servingSize.quantity
          : 1,
      servingUnit: m.servingSize.unit.isNotEmpty ? m.servingSize.unit : 'g',
      servingTime: persistedServingTime,
      tags: m.tags,
      dayGroup: dayGroup,
      secondaryLabel: m.secondaryComponent?.label ?? '',
      secondaryBaseQuantity: m.secondaryComponent?.quantity ?? 1,
      secondaryUnit: m.secondaryComponent?.unit ?? '',
      supplementFacts: m.supplementFacts,
    );
  }

  // --------------------------
  // update week -> set selectedWeekMeals and recompute shiftMeals
  // --------------------------
  void updateSelectedWeekData(int weekNumber) {
    if (dietPlanData.value == null) return;

    WeekPlan week = dietPlanData.value!.weeks.firstWhere(
      (w) => w.week == weekNumber,
    );

    selectedWeekMeals.value = week.dailyMeals;

    // Filter meals for current shift
    updateShiftMeals(selectedShift.value);

    // Update totals for this week
    calculateTotalsForWeek(weekNumber);

    debugPrint("Week changed → $weekNumber");
    debugPrint("Meals in this week: ${selectedWeekMeals.length}");
  }

  Recipe? getRecipeById(String id) {
    return dietPlanData.value?.recipes[id];
  }

  // WHEN USER SELECTS A FOODCARD
  void toggleMealSelection(Recipe recipe) {
    int currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);

    // Mark that the user has interacted with this week's selections
    _userInteractedWeeks.add(currentWeekNumber);

    List<Recipe> currentWeekRecipes =
        weekSelectedRecipes[currentWeekNumber] ?? [];

    // Supplements are meant to be identical across all 4 day-groups (see
    // buildPrompt's "Morning Drink and any Supplements pick must use the
    // exact same recipeId across all 4 day-groups" rule) and can be
    // selected from two places (their own real slot, e.g. Night Drink, and
    // the browsing-only Supplements tab - see buildServingTimeOptionsFromDocs'
    // 'supplement' tag). Treating this as one whole-week decision - not 4
    // independent per-day-group ones - means deselecting it from either
    // place actually removes it everywhere, instead of leaving it still
    // selected under the other 3 groups.
    if (recipe.tags.contains('supplement')) {
      final isCurrentlySelected = currentWeekRecipes.any(
        (r) => r.id == recipe.id && r.servingTime == recipe.servingTime,
      );
      for (final dg in dayGroups) {
        final variant = recipe.copyWith(dayGroup: dg);
        currentWeekRecipes.removeWhere(
          (r) =>
              r.id == recipe.id &&
              r.servingTime == recipe.servingTime &&
              r.dayGroup == dg,
        );
        selectedServings.remove(servingsKey(variant));
        selectedSecondaryServings.remove(servingsKey(variant));
        if (!isCurrentlySelected) {
          currentWeekRecipes.add(variant);
          selectedServings[servingsKey(variant)] = _defaultServingsForTrend(
            variant,
          );
          if (variant.hasSecondaryComponent) {
            selectedSecondaryServings[servingsKey(variant)] =
                variant.secondaryBaseQuantity;
          }
        }
      }
    } else if (currentWeekRecipes.contains(recipe)) {
      currentWeekRecipes.remove(recipe);
      selectedServings.remove(servingsKey(recipe));
      selectedSecondaryServings.remove(servingsKey(recipe));
    } else {
      currentWeekRecipes.add(recipe);
      selectedServings[servingsKey(recipe)] = _defaultServingsForTrend(recipe);
      if (recipe.hasSecondaryComponent) {
        selectedSecondaryServings[servingsKey(recipe)] =
            recipe.secondaryBaseQuantity;
      }
    }

    weekSelectedRecipes[currentWeekNumber] = currentWeekRecipes;

    // Update totals for this week
    calculateTotalsForWeek(currentWeekNumber);
  }

  // -----------------------------------------------------------------------
  // Trend-aware default/clamp/step logic (phase 4) - portions vary by the
  // patient's weight-loss/gain goal, but only within Lunch/Dinner/Evening
  // Snack where "sabji"/"side"/"salad" concepts actually apply; every other
  // slot (Breakfast, drinks, supplements) keeps the flat base-default/50g-
  // step behavior unchanged.
  // -----------------------------------------------------------------------

  static const Set<String> _trendScopedSlots = {
    'Lunch',
    'Dinner',
    'Evening Snack',
  };

  /// Gram-based trend clamping (sabji/salad ranges) only applies within
  /// Lunch/Dinner/Evening Snack, where those concepts mean something.
  /// Piece-based fractional stepping applies everywhere a piece-counted
  /// item appears (e.g. a Breakfast paratha), since "how many" is a
  /// trend-relevant question regardless of meal slot.
  bool _isTrendScoped(Recipe r) =>
      _isPieceBased(r) || _trendScopedSlots.contains(r.servingTime);

  /// The dietician-facing weight trend for the currently loaded draft -
  /// 'loss' or 'gain', derived server-side from the patient's primaryGoal
  /// (see resolveWeightTrend in dietPlanController.js).
  String get weightTrend => draftDietOptions.value?.weightTrend ?? 'gain';

  /// Distinguishes a piece-based side (Chapati/Bhakri) from a salad
  /// (tags:'salad') from everything else gram/ml-based (sabji, curry,
  /// Steamed Rice) - both salad and "everything else" are gram-unit, so
  /// unit alone can't tell them apart.
  bool _isPieceBased(Recipe r) => r.servingUnit == 'piece';
  bool _isSalad(Recipe r) => r.tags.contains('salad');

  /// Piece-based sides (Chapati, Bhakri - tags:'side', an accompaniment to
  /// a main dish) have no ceiling. Piece-based standalone dishes (Soya
  /// Sandwich, the paratha family - not tagged 'side') cap at 5.
  num? _pieceCeiling(Recipe r) => r.tags.contains('side') ? null : 5;

  /// Default quantity to seed for a never-explicitly-adjusted selection.
  num _defaultServingsForTrend(Recipe r) {
    if (!_isTrendScoped(r)) return r.baseServingQuantity;
    final isLoss = weightTrend == 'loss';
    // A slightly-below-whole default (not the smallest possible 1/4) so
    // every card doesn't start identically tiny - still clearly lighter
    // than the gain default, and the dietician can step it either way.
    if (_isPieceBased(r)) return isLoss ? 0.5 : 1;
    if (_isSalad(r)) return isLoss ? 100 : 180;
    return isLoss ? 75 : 125;
  }

  /// Clamps a stepper-adjusted value to the trend's realistic range - only
  /// within scope; out-of-scope slots (Breakfast etc.) are never clamped.
  /// Piece-based items are floored at 1/4; sides (tags:'side') have no
  /// ceiling, everything else piece-based caps at 5.
  num _clampServingsForTrend(Recipe r, num value) {
    if (!_isTrendScoped(r)) return value;
    final isLoss = weightTrend == 'loss';
    if (_isPieceBased(r)) {
      final floored = value < 0.25 ? 0.25 : value;
      final ceiling = _pieceCeiling(r);
      return ceiling != null && floored > ceiling ? ceiling : floored;
    }
    if (_isSalad(r)) {
      return isLoss ? value.clamp(75, 125) : value.clamp(155, 205);
    }
    return isLoss ? value.clamp(50, 100) : value.clamp(100, 150);
  }

  /// 1/4-step below 1 piece, 1/2-step at/above 1 - produces
  /// 1/4, 1/2, 3/4, 1, 1 1/2, 2... in both directions.
  num _pieceStep(num current, {required bool incrementing}) {
    if (incrementing) return current < 1 ? 0.25 : 0.5;
    return current > 1 ? 0.5 : 0.25;
  }

  /// Step size for the servings +/- control on gram/ml-based items (sides
  /// use [_pieceStep] instead - see incrementServings/decrementServings).
  num _servingsStep(String unit) => unit == 'piece' ? 1 : 50;

  void incrementServings(Recipe recipe) {
    final key = servingsKey(recipe);
    final current = selectedServings[key] ?? recipe.baseServingQuantity;
    // Piece-based items always use fractional stepping (see _isTrendScoped
    // - piece-based is always in scope regardless of meal slot).
    final step = _isPieceBased(recipe)
        ? _pieceStep(current, incrementing: true)
        : _servingsStep(recipe.servingUnit);
    selectedServings[key] = _clampServingsForTrend(recipe, current + step);
    final currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);
    calculateTotalsForWeek(currentWeekNumber);
  }

  void decrementServings(Recipe recipe) {
    final key = servingsKey(recipe);
    final current = selectedServings[key] ?? recipe.baseServingQuantity;
    final isTrendPiece = _isPieceBased(recipe);
    final step = isTrendPiece
        ? _pieceStep(current, incrementing: false)
        : _servingsStep(recipe.servingUnit);
    // Floor at one step - never zero/negative servings of a selected item
    // (piece-based trend items floor at 1/4 via the clamp below instead).
    final next = isTrendPiece
        ? current - step
        : (current - step < step ? step : current - step);
    selectedServings[key] = _clampServingsForTrend(recipe, next);
    final currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);
    calculateTotalsForWeek(currentWeekNumber);
  }

  /// Step size for the secondary-component +/- control (see
  /// Recipe.hasSecondaryComponent) - 1 tbsp for scoopable mix-ins, 10g for
  /// gram-based ones (e.g. chikki) - deliberately finer than the primary
  /// gram step since these are small quantities (e.g. 80g chikki total).
  num _secondaryStep(String unit) => unit == 'tbsp' ? 1 : 10;

  void incrementSecondaryServings(Recipe recipe) {
    final key = servingsKey(recipe);
    final current =
        selectedSecondaryServings[key] ?? recipe.secondaryBaseQuantity;
    final step = _secondaryStep(recipe.secondaryUnit);
    selectedSecondaryServings[key] = current + step;
    final currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);
    calculateTotalsForWeek(currentWeekNumber);
  }

  void decrementSecondaryServings(Recipe recipe) {
    final key = servingsKey(recipe);
    final current =
        selectedSecondaryServings[key] ?? recipe.secondaryBaseQuantity;
    final step = _secondaryStep(recipe.secondaryUnit);
    // Floor at one step - never zero/negative servings of a selected item.
    selectedSecondaryServings[key] = current - step < step
        ? step
        : current - step;
    final currentWeekNumber = int.parse(selectedWeek.value.split(" ").last);
    calculateTotalsForWeek(currentWeekNumber);
  }

  /// Ratio of the dietician-set servings to the recipe's own base serving -
  /// e.g. Chole adjusted to 400g / base 350g = ~1.14x. Works uniformly for
  /// piece-based items too, since their baseServingQuantity is 1 (so e.g.
  /// 3 chapatis / 1 = 3x, the same as a plain count multiplier).
  num _servingsRatio(Recipe r) {
    final servings = selectedServings[servingsKey(r)] ?? r.baseServingQuantity;
    if (r.baseServingQuantity <= 0) return 1;
    return servings / r.baseServingQuantity;
  }

  /// Same as [_servingsRatio], for the secondary component (see
  /// Recipe.hasSecondaryComponent) - 1 if there's no secondary component.
  num _secondaryServingsRatio(Recipe r) {
    if (!r.hasSecondaryComponent) return 1;
    final servings =
        selectedSecondaryServings[servingsKey(r)] ?? r.secondaryBaseQuantity;
    if (r.secondaryBaseQuantity <= 0) return 1;
    return servings / r.secondaryBaseQuantity;
  }

  /// The ratio used to scale a recipe's total nutrition. For ordinary
  /// recipes this is just [_servingsRatio]. For a compound snack with a
  /// secondary component (e.g. banana + seeds), the recipe's stated
  /// nutrition covers BOTH components together at their base quantities,
  /// and there's no per-ingredient calorie breakdown to split it precisely
  /// - the average of both components' individual ratios is a reasonable,
  /// honest approximation (not fabricated precision), consistent with the
  /// flat approximations already used elsewhere in this app (15g/tbsp,
  /// 250ml/cup).
  num _nutritionScaleRatio(Recipe r) {
    if (!r.hasSecondaryComponent) return _servingsRatio(r);
    return (_servingsRatio(r) + _secondaryServingsRatio(r)) / 2;
  }

  // Monday's meals repeat on Friday, Tuesday's on Saturday, Wednesday's on
  // Sunday - Thursday is unique (see backend utils/dayGroups.js). Shared by
  // both calculateTotalsForWeek ("Total Budget" live preview) and
  // buildFinalizeWeekPayload (what's actually submitted/stored) so the
  // dietician always sees, while editing, exactly the numbers that end up
  // saved and later shown to the patient - previously calculateTotalsForWeek
  // only summed whichever single day-group tab was active (e.g. just
  // Monday's plan) while the finalize payload computed a real 7-day
  // weighted average, so the two could show different numbers for the
  // same week.
  static const _daysRepresentedByDayGroup = {
    'Monday': 2, // + Friday
    'Tuesday': 2, // + Saturday
    'Wednesday': 2, // + Sunday
    'Thursday': 1,
  };

  /// Day-group-weighted 7-day average of calories/protein/fat/carbs/fiber
  /// across every non-supplement recipe currently selected for [weekNumber].
  Map<String, double> _weightedWeekTotals(int weekNumber) {
    // weekSelectedRecipes mixes all 4 day-groups' selections together (see
    // _applyDraftOptionsForWeek) - accumulate per day-group first, then
    // weight by how many real days that group represents, so a group with
    // more/less expensive meals doesn't just get summed flat (which would
    // double-count a 2-day group's impact once but not the other, or ignore
    // that Thursday is only 1 day vs the other groups' 2). Supplements carry
    // real supplementFacts now, not meaningful calorie/macro numbers (their
    // `nutrition` is intentionally zeroed server-side) - excluded so the
    // budget reflects food only, by construction rather than by coincidence
    // of zeroed data.
    final selectedRecipes = (weekSelectedRecipes[weekNumber] ?? [])
        .where((r) => !r.tags.contains('supplement'));

    final caloriesByDayGroup = <String, double>{};
    final fatByDayGroup = <String, double>{};
    final carbsByDayGroup = <String, double>{};
    final proteinByDayGroup = <String, double>{};
    final fiberByDayGroup = <String, double>{};

    for (final r in selectedRecipes) {
      final ratio = _nutritionScaleRatio(r);
      final dg = r.dayGroup;
      caloriesByDayGroup[dg] =
          (caloriesByDayGroup[dg] ?? 0) + r.nutrition.calories * ratio;
      fatByDayGroup[dg] = (fatByDayGroup[dg] ?? 0) + r.nutrition.fats * ratio;
      carbsByDayGroup[dg] =
          (carbsByDayGroup[dg] ?? 0) + r.nutrition.carbs * ratio;
      proteinByDayGroup[dg] =
          (proteinByDayGroup[dg] ?? 0) + r.nutrition.protein * ratio;
      fiberByDayGroup[dg] =
          (fiberByDayGroup[dg] ?? 0) + r.nutrition.fiber * ratio;
    }

    double weekCalories = 0, weekFat = 0, weekCarbs = 0, weekProtein = 0;
    double weekFiber = 0;
    _daysRepresentedByDayGroup.forEach((dayGroup, days) {
      weekCalories += (caloriesByDayGroup[dayGroup] ?? 0) * days;
      weekFat += (fatByDayGroup[dayGroup] ?? 0) * days;
      weekCarbs += (carbsByDayGroup[dayGroup] ?? 0) * days;
      weekProtein += (proteinByDayGroup[dayGroup] ?? 0) * days;
      weekFiber += (fiberByDayGroup[dayGroup] ?? 0) * days;
    });

    return {
      'calories': weekCalories / 7,
      'fat': weekFat / 7,
      'carbs': weekCarbs / 7,
      'protein': weekProtein / 7,
      'fiber': weekFiber / 7,
    };
  }

  // CALCULATE TOTAL NUTRITION ("Total Budget" card)
  void calculateTotalsForWeek(int weekNumber) {
    final totals = _weightedWeekTotals(weekNumber);
    totalCalories.value = totals['calories']!;
    totalProtein.value = totals['protein']!;
    totalFat.value = totals['fat']!;
    totalCarbs.value = totals['carbs']!;
    totalFiber.value = totals['fiber']!;
  }

  // Mirrors dietPlanValidator.js's calorie-deviation message shape exactly:
  // "Week {week}, {dayGroup}: total daily calories ({n}) deviate more than
  // {pct}% from the target budget ({budget})."
  static final RegExp _calorieDeviationWarningPattern = RegExp(
    r'^Week (\d+), (\w+): total daily calories \([\d.]+\) deviate more than \d+% from the target budget \(([\d.]+)\)\.$',
  );
  static const num _calorieDeviationTolerance = 0.1; // ±10%, matches backend

  // Mirrors dietPlanValidator.js's closed-world-check message shape exactly:
  // "Week {week}: {servingTime} references recipe "{id}" which is not in
  // the allowed recipe pool - please reselect it manually." The referenced
  // id was never real (never in recipePool), so it never became a Recipe
  // object/selection in the app - the slot just sits unselected until the
  // dietician picks a real one, exactly as the message instructs.
  static final RegExp _missingRecipeWarningPattern = RegExp(
    r'^Week (\d+): (.+) references recipe "[^"]*" which is not in the allowed recipe pool - please reselect it manually\.$',
  );

  /// validationWarnings is computed once on the backend from the AI's raw
  /// proposal, before the dietician touches anything - a warning that was
  /// true then goes stale the moment the dietician actually acts on it
  /// (nudges a serving back toward budget, or reselects a bad recipe
  /// reference). Re-checking both warning shapes here against
  /// weekSelectedRecipes/selectedServings (the dietician's live picture,
  /// same one calculateTotalsForWeek/"Total Budget" already shows) lets a
  /// resolved warning drop out of the review box immediately instead of
  /// sitting there stale until the plan is re-fetched. Every other warning
  /// (risk flags, servingTime/slot mismatches, etc.) is untouched - those
  /// aren't things a dietician resolves by editing servings/selections.
  List<String> filterStaleCalorieWarnings(List<String> warnings) {
    return warnings.where((message) {
      final calorieMatch = _calorieDeviationWarningPattern.firstMatch(
        message,
      );
      if (calorieMatch != null) {
        final week = int.tryParse(calorieMatch.group(1)!);
        final dayGroup = calorieMatch.group(2)!;
        final budget = double.tryParse(calorieMatch.group(3)!);
        if (week == null || budget == null || budget <= 0) return true;

        final liveCalories = (weekSelectedRecipes[week] ?? [])
            .where(
              (r) => r.dayGroup == dayGroup && !r.tags.contains('supplement'),
            )
            .fold<double>(
              0.0,
              (sum, r) =>
                  sum + r.nutrition.calories * _nutritionScaleRatio(r),
            );
        // Nothing selected for this day-group yet - not resolved, still warn.
        if (liveCalories <= 0) return true;

        final deviation = (liveCalories - budget).abs() / budget;
        return deviation > _calorieDeviationTolerance;
      }

      final missingMatch = _missingRecipeWarningPattern.firstMatch(message);
      if (missingMatch != null) {
        final week = int.tryParse(missingMatch.group(1)!);
        final servingTime = missingMatch.group(2)!;
        if (week == null) return true;

        final hasRealSelection = (weekSelectedRecipes[week] ?? []).any(
          (r) =>
              r.servingTime == servingTime && !r.tags.contains('supplement'),
        );
        return !hasRealSelection;
      }

      return true;
    }).toList();
  }

  // --------------------------
  // set selected shift and filter meals for that shift
  // --------------------------
  void updateSelectedShift(String shift) {
    selectedShift.value = shift;
    updateShiftMeals(shift);
  }

  void updateShiftMeals(String shift) {
    // filter selectedWeekMeals by servingTime (case-insensitive trim)
    final filtered = selectedWeekMeals.where((m) {
      final mealServing = m.servingTime.trim().toLowerCase();
      final s = shift.trim().toLowerCase();
      return mealServing == s;
    }).toList();

    shiftMeals.value = filtered;

    debugPrint("Shift '$shift' -> ${shiftMeals.length} meals");
    for (var m in shiftMeals) {
      debugPrint("  ${m.servingTime} -> ${m.recipeId}");
    }
  }

  Future<void> getConsultation(String patientId) async {
    isAllQuestionLoading.value = true;

    try {
      final response = await service.getConsultation(patientId);
      if (response == null) return;

      final data = response["data"];
      if (data == null) return;

      // ------------------------------------------------------------------
      // 1. dietaryHabitsAllergies
      // ------------------------------------------------------------------
      final dha = data["dietaryHabitsAllergies"] ?? {};

      // ----- currentEatingStyle (List OR Map) -----
      List<String> style = [];
      var ces = dha["currentEatingStyle"];

      if (ces is List) {
        style = List<String>.from(ces);
      } else if (ces is Map) {
        style = List<String>.from(ces["options"] ?? []);
        currentEatingStyleOtherInfo.text = ces["otherInfo"] ?? "";
      } else {
        currentEatingStyleOtherInfo.text = "";
      }

      for (var opt in options) {
        opt.isSelected.value = style.contains(opt.name);
      }

      // ----- allergiesIntolerances -----
      List<String> allergyList = [];
      var ai = dha["allergiesIntolerances"];

      if (ai is Map) {
        allergyList = List<String>.from(ai["options"] ?? []);
        allergiesIntolerancesOtherInfo.text = ai["otherInfo"] ?? "";
      } else {
        allergiesIntolerancesOtherInfo.text = "";
      }

      for (var opt in allergiesOrIntolerances) {
        opt.isSelected.value = allergyList.contains(opt.name);
      }

      // ----- foodsToAvoid -----
      if (dha["foodsToAvoid"] is Map) {
        foodsToAvoid.text = dha["foodsToAvoid"]["text"] ?? "";
      } else {
        foodsToAvoid.text = dha["foodsToAvoid"] ?? "";
      }

      // ----- cravings (List OR Map) -----
      List<String> cravingsList = [];
      var cr = dha["cravings"];

      if (cr is List) {
        cravingsList = List<String>.from(cr);
      } else if (cr is Map) {
        cravingsList = List<String>.from(cr["options"] ?? []);
      }

      for (var opt in cravings) {
        opt.isSelected.value = cravingsList.contains(opt.name);
      }

      // ----- who cooks meals -----
      List<String> cooksList = [];
      var wm = dha["whoCooksMeals"];

      if (wm is Map) {
        cooksList = List<String>.from(wm["options"] ?? []);
      }

      for (var opt in cooksMeals) {
        opt.isSelected.value = cooksList.contains(opt.name);
      }

      // ----- water intake -----
      waterIntake.text = dha["waterIntake"] ?? "";

      // ----- alcohol/smoking -----
      selectedAlcohol.value = dha["alcoholOrSmoking"]?["uses"] ?? "";
      alcoholOrSmokingFrequency.text =
          dha["alcoholOrSmoking"]?["frequency"] ?? "";

      // ------------------------------------------------------------------
      // 2. femaleSpecificHealth
      // ------------------------------------------------------------------
      final fsh = data["femaleSpecificHealth"] ?? {};

      selectedPeriods.value = fsh["periodsRegular"] ?? "";

      List<String> issuesList = [];
      if (fsh["issues"] is List) {
        issuesList = List<String>.from(fsh["issues"]);
      }

      for (var o in applyToYou) {
        o.isSelected.value = issuesList.contains(o.name);
      }

      List<String> medsList = [];
      if (fsh["onMedications"] is List) {
        medsList = List<String>.from(fsh["onMedications"]);
      }

      for (var o in areYouOn) {
        o.isSelected.value = medsList.contains(o.name);
      }

      // ------------------------------------------------------------------
      // 3. digestionElimination
      // ------------------------------------------------------------------
      final de = data["digestionElimination"] ?? {};

      List<String> digList = [];
      if (de["symptoms"] is List) {
        digList = List<String>.from(de["symptoms"]);
      }

      for (var o in digestionOrElimination) {
        o.isSelected.value = digList.contains(o.name);
      }

      selectedFrequencyOfBowel.value = de["bowelFrequency"] ?? "";

      // ------------------------------------------------------------------
      // 4. sleepStress
      // ------------------------------------------------------------------
      final ss = data["sleepStress"] ?? {};

      sleepStressSleepDuration.text = ss["sleepDuration"] ?? "";

      if (ss["sleepQuality"] is List && ss["sleepQuality"].isNotEmpty) {
        selectedQualityOfSleep.value = ss["sleepQuality"][0];
      }

      selectedStressLevel.value = ss["stressLevel"] ?? "";
      selectedMentalHealthConditions.value = ss["mentalHealthCondition"] ?? "";

      // ------------------------------------------------------------------
      // 5. medicationSupplements
      // ------------------------------------------------------------------
      final ms = data["medicationSupplements"] ?? {};

      selectedPrescribedMedication.value = ms["onMedication"]?["answer"] ?? "";

      medicationSupplementsDetails.text = ms["onMedication"]?["details"] ?? "";

      // supplements can be LIST or MAP
      List<String> suppList = [];
      var sup = ms["supplements"];

      if (sup is List) {
        suppList = List<String>.from(sup);
        supplementsOther.text = "";
      } else if (sup is Map) {
        suppList = List<String>.from(sup["options"] ?? []);
        supplementsOther.text = sup["other"] ?? "";
      }

      for (var o in supplements) {
        o.isSelected.value = suppList.contains(o.name);
      }

      // ------------------------------------------------------------------
      // 6. finalNotes
      // ------------------------------------------------------------------
      final fn = data["finalNotes"] ?? {};

      finalNotesConcerns.text = fn["concerns"] ?? "";
      selectedPersonalizedNutrition.value = fn["readinessToCommit"] ?? "";

      // ------------------------------------------------------------------
      // 7. labReports
      // ------------------------------------------------------------------
      final files = data["labReports"]?["files"] ?? [];

      if (files is List && files.isNotEmpty) {
        report.value = files.first.toString();
      } else {
        report.value = "";
      }

      debugPrint("Lab report files: $files");

      // ------------------------------------------------------------------
      // 8. customAnswers (answers to dietician's custom consultation form)
      // ------------------------------------------------------------------
      customAnswerValues.clear();
      final customAns = data["customAnswers"];
      if (customAns is List) {
        for (final item in customAns) {
          if (item is Map) {
            final fieldId = item['fieldId']?.toString();
            if (fieldId == null || fieldId.isEmpty) continue;
            final value = item['value'];
            if (value is List) {
              customAnswerValues[fieldId] = List<String>.from(
                value.map((e) => e.toString()),
              );
            } else {
              customAnswerValues[fieldId] = value;
            }
          }
        }
      }
      // Sync into TextEditingControllers if template already loaded.
      _ensureAnswerStateForTemplate();
    } catch (e, st) {
      debugPrint("---- GET ERROR ---- $e");
      debugPrint(st.toString());
    }

    isAllQuestionLoading.value = false;
  }

  Future<void> getPaymentProof(String patientId) async {
    proofPic.value = '';
    isProofLoading.value = true;

    try {
      final response = await service.getManualProofs(patientId);

      if (response != null &&
          response['data'] != null &&
          response['data'] is List &&
          (response['data'] as List).isNotEmpty) {
        final data = (response['data'] as List).first;

        proofPic.value = data['proofImage'] ?? "";
        paymentProofId.value = data['id']?.toString() ?? "";
        paymentProofStatus.value = data['status']?.toString() ?? "";

        totalAmount = TextEditingController(
          text: data['amountReceived']?.toString() ?? "",
        );

        pendingAmount = TextEditingController(
          text: data['amountPending']?.toString() ?? "",
        );

        paymentDes = TextEditingController(text: data['description'] ?? "");

        // Coupon info
        paymentCouponCode.value = data['couponCode']?.toString() ?? '';
        paymentDiscountPercentage.value =
            (data['discountPercentage'] as num?)?.toDouble() ?? 0;
        paymentOriginalAmount.value =
            (data['originalAmount'] as num?)?.toDouble() ?? 0;
      }
    } catch (e) {
      debugPrint('---------------$e');
    }

    isProofLoading.value = false;
  }

  Future<void> activateDietPlan(String patientId, String dietPlanId) async {
    // Check if dietPlanId is valid
    if (dietPlanId.isEmpty) {
      Get.snackbar(
        "Error",
        "No finalized diet plan found. Please create and finalize a diet plan first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final amountReceivedValue = double.tryParse(totalAmount.text.trim());
    final amountPendingValue = double.tryParse(pendingAmount.text.trim());

    if (amountReceivedValue == null || amountReceivedValue < 0) {
      Get.snackbar(
        "Error",
        "Please enter a valid Amount Received.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (amountPendingValue == null || amountPendingValue < 0) {
      Get.snackbar(
        "Error",
        "Please enter a valid Amount Pending.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (paymentProofId.value.isEmpty) {
      Get.snackbar(
        "Error",
        "No payment proof found for this patient.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    activateDietPlanLoading.value = true;
    debugPrint('🔄 Activating diet plan: $dietPlanId for patient: $patientId');

    try {
      final response = await service.activateDietPlan(
        patientId,
        dietPlanId,
        proofId: paymentProofId.value,
        amountReceived: amountReceivedValue,
        amountPending: amountPendingValue,
      );

      if (response != null) {
        if (response['success'] == true) {
          // Refresh patient profile to update status
          await getPatientProfile(patientId);
          Get.back();
          Get.snackbar(
            "Success",
            "${response['message']}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            "Error",
            response['message'] ?? "Failed to activate diet plan",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Failed to activate diet plan. Please ensure the diet plan is finalized first.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('---------------$e');
      Get.snackbar(
        "Error",
        "An error occurred while activating the diet plan",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }

    activateDietPlanLoading.value = false;
  }

  Future<void> rejectPayment(String patientId) async {
    if (paymentProofId.value.isEmpty) {
      Get.snackbar(
        "Error",
        "No payment proof found to reject.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    rejectPaymentLoading.value = true;
    debugPrint(
      '🔄 Rejecting payment proof: ${paymentProofId.value} for patient: $patientId',
    );

    try {
      final response = await service.rejectPaymentProof(
        patientId,
        paymentProofId.value,
        rejectionNoteController.text.trim(),
      );

      if (response != null) {
        if (response['success'] == true) {
          await getPatientProfile(patientId);
          rejectionNoteController.clear();
          Get.back();
          Get.snackbar(
            "Success",
            "${response['message']}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            "Error",
            response['message'] ?? "Failed to reject payment",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      debugPrint('---------------$e');
      Get.snackbar(
        "Error",
        "An error occurred while rejecting the payment",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }

    rejectPaymentLoading.value = false;
  }

  // Settles a renewal payment directly (patient already has an active
  // plan - nothing about the plan itself needs to change), skipping the
  // build/finalize/activate ceremony that activateDietPlan() requires.
  Future<void> confirmRenewalPayment(String patientId) async {
    if (paymentProofId.value.isEmpty) {
      Get.snackbar(
        "Error",
        "No payment proof found for this patient.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    confirmRenewalPaymentLoading.value = true;

    try {
      final response = await service.confirmRenewalPayment(
        patientId,
        paymentProofId.value,
      );

      if (response != null) {
        if (response['success'] == true) {
          await getPatientProfile(patientId);
          Get.back();
          Get.snackbar(
            "Success",
            "${response['message']}",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.snackbar(
            "Error",
            response['message'] ?? "Failed to confirm payment",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        Get.snackbar(
          "Error",
          "Failed to confirm payment. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('---------------$e');
      Get.snackbar(
        "Error",
        "An error occurred while confirming the payment",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
      );
    }

    confirmRenewalPaymentLoading.value = false;
  }

  Map<String, dynamic> buildFinalizeWeekPayload() {
    int weekNumber = int.parse(selectedWeek.value.split(" ").last);

    // user-selected recipes for this week - built from the options-pool
    // draft-review flow (getDraftDietOptions/weekSelectedRecipes), which is
    // now this screen's only data source (selectedWeekMeals/dietPlanData
    // belonged to the older single-recipe-per-slot flow this replaced).
    //
    // finalizeWeekPlan now keeps every selected recipe per servingTime (not
    // just one), so a Sabji + a side + a salad all selected under Lunch all
    // survive finalize.
    final selectedRecipes = weekSelectedRecipes[weekNumber] ?? [];

    final selectedMeals = selectedRecipes.map((selected) {
      return {
        "dayGroup": selected.dayGroup,
        "servingTime": selected.servingTime,
        "recipeId": selected.id,
        "servings":
            selectedServings[servingsKey(selected)] ??
            selected.baseServingQuantity,
        if (selected.hasSecondaryComponent)
          "secondaryServings":
              selectedSecondaryServings[servingsKey(selected)] ??
              selected.secondaryBaseQuantity,
      };
    }).toList();

    // Same weighted 7-day-average formula as calculateTotalsForWeek's "Total
    // Budget" preview (see _weightedWeekTotals) - guarantees this submitted
    // summary matches exactly what the dietician was just looking at, and
    // what the patient app will later read back from weeksSummary.
    final totals = _weightedWeekTotals(weekNumber);

    // backend requires summary values as **strings**
    final payload = {
      "week": weekNumber,
      "selectedMeals": selectedMeals,
      "summary": {
        "totalCalories": totals['calories']!.toStringAsFixed(0),
        "fatPercent": "0",
        "fatGrams": totals['fat']!.toStringAsFixed(0),
        "carbPercent": "0",
        "carbGrams": totals['carbs']!.toStringAsFixed(0),
        "proteinPercent": "0",
        "proteinGrams": totals['protein']!.toStringAsFixed(0),
        "fiberGrams": totals['fiber']!.toStringAsFixed(0),
      },
    };

    // Include current weight for weeks 2/3/4
    if (currentWeightForWeek.value > 0) {
      payload["currentWeight"] = currentWeightForWeek.value;
    }

    return payload;
  }

  Future<void> finalizeWeek(
    String patientId,
    String dietPlanId,
    String selectedWeek,
  ) async {
    showWeekDietSendingLoading.value = true;

    try {
      final payload = buildFinalizeWeekPayload();

      final response = await service.finalizeWeek(
        payload,
        patientId,
        dietPlanId,
      );

      if (response != null && response['success'] == true) {
        debugPrint("Week finalized successfully");
        Get.snackbar(
          "Success",
          "$selectedWeek finalized successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
        // Reset weight override
        currentWeightForWeek.value = 0.0;
        // Get.back() also closes any open snackbar as a side effect (see
        // GetNavigation.back), and calling it twice back-to-back races
        // that close against itself - the second call's closeCurrentSnackbar
        // hits the still-disposing entry from the first and trips GetX's
        // "Cannot remove entry from a disposed snackbar" assertion. Close
        // the snackbar explicitly first so both pops below are plain route
        // pops.
        if (Get.isSnackbarOpen) {
          await Get.closeCurrentSnackbar();
        }
        // Pop both SelectDietSheet and CreateDietPlanScreen (now pushed
        // full screens, not bottom sheets), then land explicitly on the
        // patient profile route - same belt-and-suspenders pattern as
        // finalizeAll below, so the dietician always exits to the profile
        // screen regardless of exactly how they navigated in.
        Get.back();
        Get.back();
        Get.offNamed('/patient-profile/$patientId');
        // Navigate first, refresh after - PatientProfileView.initState()
        // already re-fetches this same profile the instant it mounts, so
        // awaiting this call *before* navigating (the old order) just made
        // the Finalize button's spinner sit through a second full network
        // round-trip whose result gets thrown away and immediately
        // re-fetched anyway. Matches finalizeAll's ordering below.
        await getPatientProfile(patientId);
      }
    } catch (e) {
      debugPrint("Finalize Week Error: $e");
    }
    showWeekDietSendingLoading.value = false;
  }

  Map<String, dynamic> buildFinalizeAllPayload() {
    List<Map<String, dynamic>> allWeeks = [];

    for (int week = 1; week <= 4; week++) {
      final weekPlan = dietPlanData.value!.weeks.firstWhere(
        (w) => w.week == week,
      );

      final selectedRecipes = weekSelectedRecipes[week] ?? [];

      // Build dailyMeals array for this week and compute nutrition from resolved recipes
      double weekCalories = 0, weekFat = 0, weekCarbs = 0, weekProtein = 0;
      final dailyMeals = weekPlan.dailyMeals.map((meal) {
        final selected = selectedRecipes.firstWhere(
          (r) => r.id == meal.recipeId,
          orElse: () => getRecipeById(meal.recipeId)!,
        );

        weekCalories += selected.nutrition.calories;
        weekFat += selected.nutrition.fats;
        weekCarbs += selected.nutrition.carbs;
        weekProtein += selected.nutrition.protein;

        return {"servingTime": meal.servingTime, "recipeId": selected.id};
      }).toList();

      allWeeks.add({
        "week": week,
        "dailyMeals": dailyMeals,
        "summary": {
          "totalCalories": weekCalories.toStringAsFixed(0),
          "fatPercent": "0",
          "fatGrams": weekFat.toStringAsFixed(0),
          "carbPercent": "0",
          "carbGrams": weekCarbs.toStringAsFixed(0),
          "proteinPercent": "0",
          "proteinGrams": weekProtein.toStringAsFixed(0),
        },
      });
    }

    return {"weeks": allWeeks};
  }

  Future<void> finalizeAll(String patientId, String dietPlanId) async {
    showAllDietSendingLoading.value = true;
    try {
      final payload = buildFinalizeAllPayload();

      final response = await service.finalizeAll(
        payload,
        patientId,
        dietPlanId,
      );

      if (response != null && response['success'] == true) {
        // Check if payment request was auto-sent by backend
        final paymentSent = response['data']?['paymentRequestSent'] == true;

        Get.back();
        Get.back();
        Get.offNamed('/patient-profile/$patientId');
        Get.snackbar(
          "Success",
          paymentSent
              ? "All weeks finalized & payment request sent to patient!"
              : "All weeks finalized successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );

        // Update local status to reflect payment requested
        if (paymentSent) {
          patientProfileModel.value?.status?.requestStatus = 'PaymentRequested';
          patientProfileModel.refresh();
        }

        await getPatientProfile(patientId);
      }
    } catch (e) {
      debugPrint("Finalize All Error: $e");
    }
    showAllDietSendingLoading.value = false;
  }

  Future<void> sendPaymentRequest(String patientId, String requestId) async {
    // At least one week must be finalized before sending payment request
    if (!hasFinalizedWeeks) {
      Get.snackbar(
        'Cannot Send Payment',
        'Please finalize at least one week before sending a payment request.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xffFEF3F2),
        colorText: const Color(0xffB42318),
      );
      return;
    }
    isPaymentRequestSending.value = true;
    try {
      final response = await service.sendPaymentRequest(patientId, requestId);

      if (response != null) {
        debugPrint('-------------${response['message']}');
        patientProfileModel.value?.status?.requestStatus = 'PaymentRequested';

        patientProfileModel.refresh();
      }
    } catch (e) {
      debugPrint('------------------$e');
    }
    isPaymentRequestSending.value = false;
  }
  //////////////

  RxInt selectedCalories = 0.obs;
  RxDouble selectedFat = 0.0.obs;
  RxDouble selectedCarbs = 0.0.obs;
  RxDouble selectedProtein = 0.0.obs;

  Future<void> getSelectedDiet(
    String patientId,
    String dietPlanId,
    int week,
  ) async {
    showSelectedDeitLoading.value = true;

    try {
      final response = await service.getSelectedDiet(
        patientId,
        dietPlanId,
        week,
      );

      if (response != null &&
          response["success"] == true &&
          response["data"] != null) {
        final dataMap = response["data"];

        dietPlanWeekData.value = DietPlanWeekData.fromJson(dataMap);
        selectedCalories.value = response['data']['summary']['totalCalories'];
        final summary = dataMap['summary'];
        if (summary != null) {
          selectedCalories.value = summary['totalCalories']?.toInt() ?? 0;

          selectedFat.value = (summary['fatGrams']?.toDouble() ?? 0) / 10;
          selectedCarbs.value = (summary['carbGrams']?.toDouble() ?? 0) / 100;
          selectedProtein.value =
              (summary['proteinGrams']?.toDouble() ?? 0) / 10;
        }
        updateGetShiftMeals();
      } else {
        Get.snackbar("Error", "Failed to load week data");
      }
    } catch (e) {
      debugPrint("---------------------> $e");
    }

    showSelectedDeitLoading.value = false;
  }

  void updateGetShiftMeals() {
    final data = dietPlanWeekData.value;
    if (data == null) return;

    final allServingTimes = data.dayGroups.expand((g) => g.servingTimes);
    final shiftData = allServingTimes.firstWhere(
      (e) => e.servingTime == getSelectedShift.value,
      orElse: () =>
          ServingTimeModel(servingTime: '', selectedRecipeId: '', recipes: []),
    );

    getShiftMeals.assignAll(shiftData.recipes);
  }

  void toggleRecipeSelection(String recipeId) {
    // Find which serving time this recipe belongs to
    final weekData = dietPlanWeekData.value;
    final allServingTimes = weekData == null
        ? <ServingTimeModel>[]
        : weekData.dayGroups.expand((g) => g.servingTimes).toList();
    for (var st in allServingTimes) {
      final matchIndex = st.recipes.indexWhere((r) => r.id == recipeId);
      if (matchIndex != -1) {
        final isCurrentlySelected = st.recipes[matchIndex].isSelected;
        // Deselect all recipes in this serving time first (single-select)
        for (var r in st.recipes) {
          r.isSelected = false;
        }
        // Toggle the tapped one (if it was selected, it stays deselected)
        if (!isCurrentlySelected) {
          st.recipes[matchIndex].isSelected = true;
        }
        break;
      }
    }
    updateGetShiftMeals();
    calculateSelectedNutrition();
  }

  void calculateSelectedNutrition() {
    int calories = 0;
    double fat = 0;
    double carbs = 0;
    double protein = 0;

    final weekData = dietPlanWeekData.value;
    final allServingTimes = weekData == null
        ? <ServingTimeModel>[]
        : weekData.dayGroups.expand((g) => g.servingTimes).toList();
    for (var st in allServingTimes) {
      for (var r in st.recipes) {
        if (r.isSelected) {
          // cast dynamic to num first
          final cal = r.nutrition.calories as num;
          final f = r.nutrition.fats as num;
          final c = r.nutrition.carbs as num;
          final p = r.nutrition.protein as num;

          calories += cal.toInt();
          fat += f.toDouble();
          carbs += c.toDouble();
          protein += p.toDouble();
        }
      }
    }

    selectedCalories.value = calories;
    selectedFat.value = fat;
    selectedCarbs.value = carbs;
    selectedProtein.value = protein;
  }

  Map<String, dynamic> buildSelectedDietPayload(int weekNumber) {
    final data = dietPlanWeekData.value;
    if (data == null) return {};

    final weekMeals = data.dayGroups.expand((g) => g.servingTimes).toList();

    final selectedMeals = weekMeals.map((meal) {
      // find recipe the user selected
      final selectedRecipe = meal.recipes.firstWhere(
        (r) => r.isSelected,
        orElse: () => RecipeModel(
          id: '',
          name: '',
          image: '',
          nutrition: NutritionModel(
            calories: 0,
            protein: 0,
            carbs: 0,
            fats: 0,
            fiber: 0,
          ),
          servingTime: meal.servingTime,
          isSelected: false,
          nextWeekTag: null,
          servingSize: ServingSizeModel(quantity: 0, unit: ''),
        ),
      );

      return {"servingTime": meal.servingTime, "recipeId": selectedRecipe.id};
    }).toList();

    return {
      "week": weekNumber,
      "selectedMeals": selectedMeals,
      "summary": {
        "totalCalories": selectedCalories.value.toString(),
        "fatPercent": "0",
        "fatGrams": selectedFat.value.toString(),
        "carbPercent": "0",
        "carbGrams": selectedCarbs.value.toString(),
        "proteinPercent": "0",
        "proteinGrams": selectedProtein.value.toString(),
      },
    };
  }

  Future<void> updateSelectedDiet(
    String patientId,
    String dietPlanId,
    int week,
  ) async {
    updatingWeekItem.value = true;

    try {
      final payload = buildSelectedDietPayload(week);
      // Convert Dart map to pretty JSON
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(payload);
      debugPrint("Payload being sent:\n$prettyJson");

      final response = await service.finalizeWeek(
        payload,
        patientId,
        dietPlanId,
      );

      if (response != null && response['success'] == true) {
        debugPrint("Selected Diet Updated Successfully");
        // Refresh the patient profile data so the UI reflects changes
        await getPatientProfile(patientId);
        Get.back();
        Get.snackbar(
          "Success",
          "Week $week updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint("Update Selected Diet Error: $e");
    }

    updatingWeekItem.value = false;
  }

  // ===== Client Logged Data Methods =====

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchClientLogData(String patientId, {DateTime? date}) async {
    isClientLogLoading.value = true;
    final targetDate = date ?? clientLogSelectedDate.value;
    final dateStr = _formatDate(targetDate);

    try {
      final results = await Future.wait([
        service.fetchPatientMealLogStats(patientId, date: dateStr),
        service.fetchPatientWaterIntake(patientId, date: dateStr),
      ]);

      final mealResponse = results[0];
      final waterResponse = results[1];

      if (mealResponse != null && mealResponse['success'] == true) {
        final data = Map<String, dynamic>.from(mealResponse['data'] ?? {});
        clientMealStats.value = data;
        final List meals = data['meals'] ?? [];
        clientMeals.value = meals
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        clientMealStats.value = {};
        clientMeals.value = [];
      }

      if (waterResponse != null && waterResponse['success'] == true) {
        clientWaterData.value = Map<String, dynamic>.from(
          waterResponse['data'] ?? {},
        );
      } else {
        clientWaterData.value = {};
      }
    } catch (e) {
      debugPrint('fetchClientLogData error: $e');
    }

    isClientLogLoading.value = false;
  }

  void changeClientLogDate(String patientId, int daysDelta) {
    clientLogSelectedDate.value = clientLogSelectedDate.value.add(
      Duration(days: daysDelta),
    );
    fetchClientLogData(patientId, date: clientLogSelectedDate.value);
  }

  List<Map<String, dynamic>> getMealsForServingTime(String servingTime) {
    return clientMeals.where((m) => m['servingTime'] == servingTime).toList();
  }

  // ===== Doctor Notes Methods =====

  Future<void> fetchDoctorNotes(String patientId) async {
    isDoctorNotesLoading.value = true;
    try {
      final response = await service.fetchDoctorNotes(patientId);
      if (response != null && response['success'] == true) {
        final List data = response['data'] ?? [];
        doctorNotes.value = data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('fetchDoctorNotes error: $e');
    }
    isDoctorNotesLoading.value = false;
  }

  Future<bool> sendDoctorNote({
    required String patientId,
    required String noteContent,
    DateTime? noteDate,
  }) async {
    isSendingNote.value = true;
    try {
      final response = await service.sendDoctorNote(
        patientId: patientId,
        noteContent: noteContent,
        noteDate: noteDate?.toIso8601String(),
      );

      if (response != null && response['success'] == true) {
        // Refresh notes list
        await fetchDoctorNotes(patientId);
        isSendingNote.value = false;
        return true;
      }
    } catch (e) {
      debugPrint('sendDoctorNote error: $e');
    }
    isSendingNote.value = false;
    return false;
  }
}

class SingleDietOption {
  String name;
  SingleDietOption({required this.name});
}
