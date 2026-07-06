class PatientRequestModel {
  String? id;
  String? patientId;
  String? patientName;
  String? avatarUrl;
  String? primaryGoal;
  String? startDateForDiet;
  String? status;
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
    this.createdAt,
    this.updatedAt,
  });

  PatientRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    patientId = json['patientId'];
    patientName = json['patientName'];
    avatarUrl = json['avatarUrl'];
    primaryGoal = json['primaryGoal'];
    startDateForDiet = json['startDateForDiet'];
    status = json['status'];
    createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString());
    updatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString());
  }
}
