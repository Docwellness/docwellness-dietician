class PatientRequestModel {
  String? id;
  String? patientId;
  String? patientName;
  String? avatarUrl;
  String? primaryGoal;
  String? startDateForDiet;
  String? status;
  String? membershipPlan;

  /// True once a diet plan has been built/activated for this client. The
  /// Home "New client requests" list shows only requests where this is
  /// false (client asked for a diet, none assigned yet).
  bool hasActivePlan;
  int plansCount;
  DateTime? completedAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  PatientRequestModel({
    this.id,
    this.patientId,
    this.patientName,
    this.avatarUrl,
    this.primaryGoal,
    this.startDateForDiet,
    this.status,
    this.membershipPlan,
    this.hasActivePlan = false,
    this.plansCount = 0,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  PatientRequestModel.fromJson(Map<String, dynamic> json)
      : hasActivePlan = json['hasActivePlan'] == true,
        plansCount = json['plansCount'] is int
            ? json['plansCount'] as int
            : int.tryParse('${json['plansCount']}') ?? 0 {
    id = json['id'];
    patientId = json['patientId'];
    patientName = json['patientName'];
    avatarUrl = json['avatarUrl'];
    primaryGoal = json['primaryGoal'];
    startDateForDiet = json['startDateForDiet'];
    status = json['status'];
    membershipPlan = json['membershipPlan'];
    completedAt = DateTime.tryParse((json['completedAt'] ?? '').toString());
    createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString());
    updatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString());
  }

  /// A client who requested a diet and has none assigned yet.
  bool get needsDietPlan => !hasActivePlan && completedAt == null;
}
