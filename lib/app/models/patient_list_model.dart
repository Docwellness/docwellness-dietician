/// Model for Ongoing patients tab
class OngoingPatientModel {
  String? patientId;
  String? fullName;
  String? avatarUrl;
  int? streakDays;
  String? trendText;
  double? progressFromKg;
  double? progressToKg;
  double? adherencePercent;
  double? bmiValue;
  bool isActive;
  String? status;
  String? membershipPlan;

  OngoingPatientModel({
    this.patientId,
    this.fullName,
    this.avatarUrl,
    this.streakDays,
    this.trendText,
    this.progressFromKg,
    this.progressToKg,
    this.adherencePercent,
    this.bmiValue,
    this.isActive = true,
    this.status,
    this.membershipPlan,
  });

  factory OngoingPatientModel.fromJson(Map<String, dynamic> json) {
    return OngoingPatientModel(
      patientId: json['patientId'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      streakDays: (json['streakDays'] as num?)?.toInt(),
      trendText: json['trendText'],
      progressFromKg: (json['progressFromKg'] as num?)?.toDouble(),
      progressToKg: (json['progressToKg'] as num?)?.toDouble(),
      adherencePercent: (json['adherencePercent'] as num?)?.toDouble(),
      bmiValue: (json['bmiValue'] as num?)?.toDouble(),
      isActive: json['isActive'] != false,
      status: json['status']?.toString(),
      membershipPlan: json['membershipPlan']?.toString(),
    );
  }
}

/// Model for New patients tab
class NewPatientModel {
  String? patientId;
  String? fullName;
  String? avatarUrl;
  double? weight;
  double? bmi;
  double? bmr;
  double? tdee;
  String? statusCode;
  String? statusLabel;
  String? membershipPlan;

  NewPatientModel({
    this.patientId,
    this.fullName,
    this.avatarUrl,
    this.weight,
    this.bmi,
    this.bmr,
    this.tdee,
    this.statusCode,
    this.statusLabel,
    this.membershipPlan,
  });

  factory NewPatientModel.fromJson(Map<String, dynamic> json) {
    return NewPatientModel(
      patientId: json['patientId']?.toString(),
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      weight: (json['weight'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmr: (json['bmr'] as num?)?.toDouble(),
      tdee: (json['tdee'] as num?)?.toDouble(),
      statusCode: json['statusCode']?.toString(),
      statusLabel: json['statusLabel']?.toString(),
      membershipPlan: json['membershipPlan']?.toString(),
    );
  }
}

/// Model for Past patients tab
class PastPatientModel {
  String? patientId;
  String? fullName;
  String? avatarUrl;
  double? finalWeight;
  double? totalKgLost;
  double? bmiBefore;
  double? bmiAfter;
  String? completedOn;

  PastPatientModel({
    this.patientId,
    this.fullName,
    this.avatarUrl,
    this.finalWeight,
    this.totalKgLost,
    this.bmiBefore,
    this.bmiAfter,
    this.completedOn,
  });

  factory PastPatientModel.fromJson(Map<String, dynamic> json) {
    return PastPatientModel(
      patientId: json['patientId'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      finalWeight: (json['finalWeight'] as num?)?.toDouble(),
      totalKgLost: (json['totalKgLost'] as num?)?.toDouble(),
      bmiBefore: (json['bmiBefore'] as num?)?.toDouble(),
      bmiAfter: (json['bmiAfter'] as num?)?.toDouble(),
      completedOn: json['completedOn'],
    );
  }
}
