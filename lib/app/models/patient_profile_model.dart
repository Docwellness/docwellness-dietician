class PatientProfileModel {
  String? id;
  Basic? basic;
  HealthSummary? healthSummary;
  Status? status;
  List<WeeklyDietPlan>? weeklyDietPlans;

  PatientProfileModel({
    this.id,
    this.basic,
    this.healthSummary,
    this.status,
    this.weeklyDietPlans,
  });

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
  }
}

class Basic {
  String? fullName;
  String? username;
  String? email;
  String? whatsappNumber;
  String? gender;
  String? dateOfBirth;
  String? profileImage;

  Basic({
    this.fullName,
    this.username,
    this.email,
    this.whatsappNumber,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
  });

  Basic.fromJson(Map<String, dynamic> json) {
    fullName = json['fullName'];
    username = json['username'];
    email = json['email'];
    whatsappNumber = json['whatsappNumber'];
    gender = json['gender'];
    dateOfBirth = json['dateOfBirth'];
    profileImage = json['profileImage'];
  }
}

class HealthSummary {
  int? height;
  int? weight;
  double? bmi;
  int? weightIndex;
  String? primaryGoal;
  String? targetWeight;
  String? activityLevel;
  List<String>? healthConcerns;

  HealthSummary({
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
  String? activeDietPlanId;
  String? requestId;
  String? requestStatus;
  bool? canSendPaymentRequest;
  bool? hasPaymentUpdate;
  bool? isActive;
  String? subscriptionExpiresAt;
  PaymentSummary? paymentSummary;

  Status({
    this.isProfileComplete,
    this.firstConsultationId,
    this.activeDietPlanId,
    this.requestId,
    this.requestStatus,
    this.canSendPaymentRequest,
    this.hasPaymentUpdate,
    this.isActive,
    this.subscriptionExpiresAt,
    this.paymentSummary,
  });

  Status.fromJson(Map<String, dynamic> json) {
    isProfileComplete = json['isProfileComplete'];
    firstConsultationId = json['firstConsultationId'];
    activeDietPlanId = json['activeDietPlanId'];
    requestId = json['requestId'];
    requestStatus = json['requestStatus'];
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

  PaymentSummary({
    this.amountReceived,
    this.amountPending,
    this.totalAmount,
    this.proofStatus,
  });

  PaymentSummary.fromJson(Map<String, dynamic> json) {
    amountReceived = (json['amountReceived'] as num?)?.toDouble();
    amountPending = (json['amountPending'] as num?)?.toDouble();
    totalAmount = (json['totalAmount'] as num?)?.toDouble();
    proofStatus = json['proofStatus'];
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
