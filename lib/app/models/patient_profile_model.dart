class PatientProfileModel {
  String? id;
  Basic? basic;
  HealthSummary? healthSummary;
  Status? status;
  List<WeeklyDietPlan>? weeklyDietPlans;
  // Weeks with AI-generated content ready for meal selection, even before
  // finalization (weeklyDietPlans only reflects finalized weeks) - drives
  // the tier-gated weekly-card states (generated / eligible / locked).
  List<int> generatedWeekNumbers = [];
  // The Calorie/Macro strategy actually used for the patient's active diet
  // plan (see DietPlan.js's calorieStrategy/macroStrategy) - null until a
  // plan exists. Lets CreateDietPlanScreen re-open with the dietician's
  // prior selection pre-filled instead of a blank form.
  ActivePlanStrategy? activePlanStrategy;
  // Per-week date ranges for the active plan's cycle (see
  // utils/weekSchedule.js on the backend) - internal week numbers 1-4
  // regardless of cycle; combine with status.cycleNumber via displayWeek()
  // to show "Week 5" etc. for a renewed patient's second cycle onward.
  List<WeekScheduleEntry> weekSchedule = [];
  // The next cycle being built while the current one is still running
  // (status.renewalPending). Null outside a renewal. Its own week-state
  // signals drive the "Week 5-8" cards + Create/Resume button under the
  // Weekly Diet Plans section.
  PendingCycle? pendingCycle;
  // One entry per renewal cycle this patient has ever had, newest first -
  // the Payment Information section renders these as collapsed, dated rows
  // once there's more than one (a patient who never renewed just has the
  // single current-cycle entry, same info status.paymentSummary already has).
  List<PaymentHistoryEntry> paymentHistory = [];

  PatientProfileModel({
    this.id,
    this.basic,
    this.healthSummary,
    this.status,
    this.weeklyDietPlans,
    List<int>? generatedWeekNumbers,
    this.activePlanStrategy,
    List<WeekScheduleEntry>? weekSchedule,
    this.pendingCycle,
    List<PaymentHistoryEntry>? paymentHistory,
  }) : generatedWeekNumbers = generatedWeekNumbers ?? [],
       weekSchedule = weekSchedule ?? [],
       paymentHistory = paymentHistory ?? [];

  PatientProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    basic = json['basic'] != null ? Basic.fromJson(json['basic']) : null;
    healthSummary = json['healthSummary'] != null
        ? HealthSummary.fromJson(json['healthSummary'])
        : null;
    status = json['status'] != null ? Status.fromJson(json['status']) : null;

    if (json['weeklyDietPlans'] != null) {
      weeklyDietPlans = List<WeeklyDietPlan>.from(
        json['weeklyDietPlans'].map((x) => WeeklyDietPlan.fromJson(x)),
      );
    }

    generatedWeekNumbers = json['generatedWeekNumbers'] != null
        ? List<int>.from(json['generatedWeekNumbers'])
        : [];

    activePlanStrategy = json['activePlanStrategy'] != null
        ? ActivePlanStrategy.fromJson(json['activePlanStrategy'])
        : null;

    weekSchedule = json['weekSchedule'] != null
        ? List<WeekScheduleEntry>.from(
            json['weekSchedule'].map((x) => WeekScheduleEntry.fromJson(x)),
          )
        : [];

    pendingCycle = json['pendingCycle'] != null
        ? PendingCycle.fromJson(json['pendingCycle'])
        : null;

    paymentHistory = json['paymentHistory'] != null
        ? List<PaymentHistoryEntry>.from(
            json['paymentHistory'].map((x) => PaymentHistoryEntry.fromJson(x)),
          )
        : [];
  }

  /// Converts an internal 1-4 week number into the display number a renewed
  /// patient should see (Week 5-8 for cycle 2, 9-12 for cycle 3, etc.).
  int displayWeek(int internalWeek) =>
      ((status?.cycleNumber ?? 1) - 1) * 4 + internalWeek;

  WeekScheduleEntry? scheduleFor(int internalWeek) {
    for (final entry in weekSchedule) {
      if (entry.week == internalWeek) return entry;
    }
    return null;
  }
}

class WeekScheduleEntry {
  int? week;
  DateTime? startDate;
  DateTime? endDate;

  WeekScheduleEntry({this.week, this.startDate, this.endDate});

  WeekScheduleEntry.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    startDate = json['startDate'] != null
        ? DateTime.tryParse(json['startDate'].toString())
        : null;
    endDate = json['endDate'] != null
        ? DateTime.tryParse(json['endDate'].toString())
        : null;
  }
}

/// The renewal cycle a dietician is building while the patient's current
/// cycle is still live (see backend patientController's `pendingCycle`).
class PendingCycle {
  String? dietPlanId;
  String? status; // Draft / Finalized / Active
  String? workflowStatus; // targets_set / menu_generated / ...
  String? dataModel; // plan-item / days-array
  int cycleNumber;
  List<WeekScheduleEntry> weekSchedule;
  List<int> generatedWeekNumbers;
  List<int> finalizedWeekNumbers;
  ActivePlanStrategy? activePlanStrategy;

  PendingCycle({
    this.dietPlanId,
    this.status,
    this.workflowStatus,
    this.dataModel,
    this.cycleNumber = 1,
    this.weekSchedule = const [],
    this.generatedWeekNumbers = const [],
    this.finalizedWeekNumbers = const [],
    this.activePlanStrategy,
  });

  PendingCycle.fromJson(Map<String, dynamic> json)
      : cycleNumber = json['cycleNumber'] ?? 1,
        weekSchedule = json['weekSchedule'] != null
            ? List<WeekScheduleEntry>.from(
                json['weekSchedule'].map((x) => WeekScheduleEntry.fromJson(x)),
              )
            : const [],
        generatedWeekNumbers = json['generatedWeekNumbers'] != null
            ? List<int>.from(json['generatedWeekNumbers'])
            : const [],
        finalizedWeekNumbers = json['finalizedWeekNumbers'] != null
            ? List<int>.from(json['finalizedWeekNumbers'])
            : const [] {
    dietPlanId = json['dietPlanId']?.toString();
    status = json['status'];
    workflowStatus = json['workflowStatus'];
    dataModel = json['dataModel'];
    activePlanStrategy = json['activePlanStrategy'] != null
        ? ActivePlanStrategy.fromJson(json['activePlanStrategy'])
        : null;
  }

  /// Internal week 1-4 -> the display number for this cycle (Week 5-8 for
  /// cycle 2, etc.).
  int displayWeek(int internalWeek) => (cycleNumber - 1) * 4 + internalWeek;

  WeekScheduleEntry? scheduleFor(int internalWeek) {
    for (final entry in weekSchedule) {
      if (entry.week == internalWeek) return entry;
    }
    return null;
  }
}

class ActivePlanStrategy {
  CalorieStrategy? calorieStrategy;
  MacroStrategy? macroStrategy;

  ActivePlanStrategy({this.calorieStrategy, this.macroStrategy});

  ActivePlanStrategy.fromJson(Map<String, dynamic> json) {
    calorieStrategy = json['calorieStrategy'] != null
        ? CalorieStrategy.fromJson(json['calorieStrategy'])
        : null;
    macroStrategy = json['macroStrategy'] != null
        ? MacroStrategy.fromJson(json['macroStrategy'])
        : null;
  }
}

class CalorieStrategy {
  // 'Gentle' | 'Steady' | 'Accelerated' | 'Extreme' - matches a
  // CreateDietPlanScreen plan card's title exactly.
  String? name;
  num? calorieBudget;
  num? calorieDeficit;
  num? weeklyWeightLossKg;
  num? durationWeeks;

  CalorieStrategy({
    this.name,
    this.calorieBudget,
    this.calorieDeficit,
    this.weeklyWeightLossKg,
    this.durationWeeks,
  });

  CalorieStrategy.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    calorieBudget = json['calorieBudget'] as num?;
    calorieDeficit = json['calorieDeficit'] as num?;
    weeklyWeightLossKg = json['weeklyWeightLossKg'] as num?;
    durationWeeks = json['durationWeeks'] as num?;
  }
}

class MacroStrategy {
  // 'Balanced' | 'Low-Carb' - matches a macrosBox's title exactly.
  String? name;
  num? fatPercent;
  num? carbsPercent;
  num? proteinPercent;
  num? fiberGrams;

  MacroStrategy({
    this.name,
    this.fatPercent,
    this.carbsPercent,
    this.proteinPercent,
    this.fiberGrams,
  });

  MacroStrategy.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    fatPercent = json['fatPercent'] as num?;
    carbsPercent = json['carbsPercent'] as num?;
    proteinPercent = json['proteinPercent'] as num?;
    fiberGrams = json['fiberGrams'] as num?;
  }
}

class Basic {
  String? fullName;
  String? email;
  String? whatsappNumber;
  String? gender;
  String? dateOfBirth;
  String? profileImage;

  Basic({
    this.fullName,
    this.email,
    this.whatsappNumber,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
  });

  Basic.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'];
    email = json['email'];
    whatsappNumber = json['whatsappNumber'];
    gender = json['gender'];
    dateOfBirth = json['dateOfBirth'];
    profileImage = json['profileImage'];
  }
}

class HealthSummary {
  String? startDateForDiet;
  int? height;
  int? weight;
  double? bmi;
  int? weightIndex;
  String? primaryGoal;
  String? targetWeight;
  String? activityLevel;
  List<String>? healthConcerns;

  HealthSummary({
    this.startDateForDiet,
    this.height,
    this.weight,
    this.bmi,
    this.weightIndex,
    this.primaryGoal,
    this.targetWeight,
    this.activityLevel,
    this.healthConcerns,
  });

  HealthSummary.fromJson(Map<String, dynamic> json) {
    startDateForDiet = json['startDateForDiet'];
    height = json['height'];
    weight = json['weight'];
    bmi = (json['bmi'] as num?)?.toDouble();
    weightIndex = json['weightIndex'];
    primaryGoal = json['primaryGoal'];
    targetWeight = json['targetWeight'];
    activityLevel = json['activityLevel'];

    healthConcerns = json['healthConcerns'] != null
        ? List<String>.from(json['healthConcerns'])
        : null;
  }
}

class Status {
  bool? isProfileComplete;
  String? firstConsultationId;
  // True once the patient has reviewed the first consultation and submitted
  // the Consent & Confidentiality section themselves - required before
  // "Create Diet Plan" unlocks.
  bool? patientConsented;
  String? activeDietPlanId;
  // Status of the plan activeDietPlanId points at right now - 'Finalized'
  // means it needs Confirm & Activate, 'Active' means it's already live.
  String? activeDietPlanStatus;
  // How far the build wizard got on a still-Draft plan: targets_set ->
  // menu_generated -> portions_refined -> finalized. Null when there's no
  // in-progress plan. Lets "Create Diet Plan" resume at the right step.
  String? activeDietPlanWorkflowStatus;
  // 'plan-item' | 'days-array' | null - the resumed wizard needs this for
  // the Timeline step's supplement-flush endpoint choice.
  String? activeDietPlanDataModel;
  // Which renewal cycle the active plan belongs to (1 = first plan ever
  // built for this patient, incremented per renewal) - see
  // PatientProfileModel.displayWeek().
  int? cycleNumber;
  String? requestId;
  String? requestStatus;
  // The tier the *currently active* cycle was sold as (NOT a pending
  // renewal's pick) - drives the profile badge + avatar ring.
  String? membershipPlan;
  // Normalized 'silver' | 'golden' | 'platinum' | null - drives which
  // weekly-plan generation cadence applies (see patients_controller.dart).
  String? membershipTier;
  // A renewal has been requested and its plan is being built while the
  // current cycle stays live. Badge/ring/weekly-plan swap wait for the
  // dietician to activate the new cycle.
  bool renewalPending = false;
  // The tier the patient picked for the pending renewal (shown as a hint,
  // never as the active badge). Null unless renewalPending.
  String? pendingMembershipPlan;
  String? pendingMembershipTier;
  bool? canSendPaymentRequest;
  bool? hasPaymentUpdate;
  bool? isActive;
  String? subscriptionExpiresAt;
  PaymentSummary? paymentSummary;

  Status({
    this.isProfileComplete,
    this.firstConsultationId,
    this.patientConsented,
    this.activeDietPlanId,
    this.activeDietPlanStatus,
    this.activeDietPlanWorkflowStatus,
    this.activeDietPlanDataModel,
    this.cycleNumber,
    this.requestId,
    this.requestStatus,
    this.membershipPlan,
    this.membershipTier,
    this.renewalPending = false,
    this.pendingMembershipPlan,
    this.pendingMembershipTier,
    this.canSendPaymentRequest,
    this.hasPaymentUpdate,
    this.isActive,
    this.subscriptionExpiresAt,
    this.paymentSummary,
  });

  Status.fromJson(Map<String, dynamic> json) {
    isProfileComplete = json['isProfileComplete'];
    firstConsultationId = json['firstConsultationId'];
    patientConsented = json['patientConsented'] == true;
    activeDietPlanId = json['activeDietPlanId'];
    activeDietPlanStatus = json['activeDietPlanStatus'];
    activeDietPlanWorkflowStatus = json['activeDietPlanWorkflowStatus'];
    activeDietPlanDataModel = json['activeDietPlanDataModel'];
    cycleNumber = json['cycleNumber'];
    requestId = json['requestId'];
    requestStatus = json['requestStatus'];
    membershipPlan = json['membershipPlan'];
    membershipTier = json['membershipTier'];
    renewalPending = json['renewalPending'] == true;
    pendingMembershipPlan = json['pendingMembershipPlan'];
    pendingMembershipTier = json['pendingMembershipTier'];
    canSendPaymentRequest = json['canSendPaymentRequest'];
    hasPaymentUpdate = json['hasPaymentUpdate'];
    isActive = json['isActive'];
    subscriptionExpiresAt = json['subscriptionExpiresAt'];
    paymentSummary = json['paymentSummary'] != null
        ? PaymentSummary.fromJson(json['paymentSummary'])
        : null;
  }
}

class PaymentSummary {
  double? amountReceived;
  double? amountPending;
  double? totalAmount;
  String? proofStatus;
  String? couponCode;
  double? discountPercentage;
  double? originalAmount;
  DateTime? pendingPaymentDate;
  // Set once a previously-outstanding balance is fully cleared - the date
  // the clearing payment was approved, replacing the now-resolved promise
  // date as the relevant "when" to show.
  DateTime? balanceClearedAt;

  PaymentSummary({
    this.amountReceived,
    this.amountPending,
    this.totalAmount,
    this.proofStatus,
    this.couponCode,
    this.discountPercentage,
    this.originalAmount,
    this.pendingPaymentDate,
    this.balanceClearedAt,
  });

  PaymentSummary.fromJson(Map<String, dynamic> json) {
    amountReceived = (json['amountReceived'] as num?)?.toDouble();
    amountPending = (json['amountPending'] as num?)?.toDouble();
    totalAmount = (json['totalAmount'] as num?)?.toDouble();
    proofStatus = json['proofStatus'];
    couponCode = json['couponCode'];
    discountPercentage = (json['discountPercentage'] as num?)?.toDouble();
    originalAmount = (json['originalAmount'] as num?)?.toDouble();
    pendingPaymentDate = json['pendingPaymentDate'] != null
        ? DateTime.tryParse(json['pendingPaymentDate'].toString())
        : null;
    balanceClearedAt = json['balanceClearedAt'] != null
        ? DateTime.tryParse(json['balanceClearedAt'].toString())
        : null;
  }
}

/// One renewal cycle's payment record (see PatientProfileModel.paymentHistory).
class PaymentHistoryEntry {
  String? dietPlanId;
  int cycleNumber;
  String? membershipPlan;
  String? membershipTier;
  DateTime? date;
  bool isCurrent;
  PaymentSummary? paymentSummary;

  PaymentHistoryEntry({
    this.dietPlanId,
    this.cycleNumber = 1,
    this.membershipPlan,
    this.membershipTier,
    this.date,
    this.isCurrent = false,
    this.paymentSummary,
  });

  PaymentHistoryEntry.fromJson(Map<String, dynamic> json)
      : cycleNumber = json['cycleNumber'] ?? 1,
        isCurrent = json['isCurrent'] == true {
    dietPlanId = json['dietPlanId']?.toString();
    membershipPlan = json['membershipPlan'];
    membershipTier = json['membershipTier'];
    date = json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null;
    paymentSummary = json['paymentSummary'] != null
        ? PaymentSummary.fromJson(json['paymentSummary'])
        : null;
  }
}

class WeeklyDietPlan {
  int? week;
  int? totalCalories;

  WeeklyDietPlan({this.week, this.totalCalories});

  WeeklyDietPlan.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    totalCalories = json['totalCalories'];
  }
}
