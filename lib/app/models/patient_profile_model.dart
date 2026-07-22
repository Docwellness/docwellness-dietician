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

  PatientProfileModel({
    this.id,
    this.basic,
    this.healthSummary,
    this.status,
    this.weeklyDietPlans,
    List<int>? generatedWeekNumbers,
    this.activePlanStrategy,
  }) : generatedWeekNumbers = generatedWeekNumbers ?? [];

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
  // Status of the plan activeDietPlanId points at right now - 'Active' means
  // a PaymentSubmitted request is a renewal (plan already usable, payment
  // just needs settling); 'Finalized' means it's a genuine first activation.
  String? activeDietPlanStatus;
  String? requestId;
  String? requestStatus;
  String? membershipPlan;
  // Normalized 'silver' | 'golden' | 'platinum' | null - drives which
  // weekly-plan generation cadence applies (see patients_controller.dart).
  String? membershipTier;
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
    this.requestId,
    this.requestStatus,
    this.membershipPlan,
    this.membershipTier,
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
    requestId = json['requestId'];
    requestStatus = json['requestStatus'];
    membershipPlan = json['membershipPlan'];
    membershipTier = json['membershipTier'];
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

class WeeklyDietPlan {
  int? week;
  int? totalCalories;

  WeeklyDietPlan({this.week, this.totalCalories});

  WeeklyDietPlan.fromJson(Map<String, dynamic> json) {
    week = json['week'];
    totalCalories = json['totalCalories'];
  }
}
