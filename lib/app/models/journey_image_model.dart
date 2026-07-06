class JourneyImageModel {
  final String id;
  final String patientId;
  final String dieticianId;
  final String uploadedBy;
  final String uploadedByRole;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String description;
  final String dayLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  JourneyImageModel({
    required this.id,
    required this.patientId,
    required this.dieticianId,
    required this.uploadedBy,
    required this.uploadedByRole,
    this.beforeImageUrl = '',
    this.afterImageUrl = '',
    this.description = '',
    this.dayLabel = 'Day 1',
    required this.createdAt,
    required this.updatedAt,
  });

  factory JourneyImageModel.fromJson(Map<String, dynamic> json) {
    return JourneyImageModel(
      id: json['_id'] ?? '',
      patientId: json['patientId'] is Map
          ? json['patientId']['_id'] ?? ''
          : json['patientId'] ?? '',
      dieticianId: json['dieticianId'] is Map
          ? json['dieticianId']['_id'] ?? ''
          : json['dieticianId'] ?? '',
      uploadedBy: json['uploadedBy'] is Map
          ? json['uploadedBy']['_id'] ?? ''
          : json['uploadedBy'] ?? '',
      uploadedByRole: json['uploadedByRole'] ?? 'patient',
      beforeImageUrl: json['beforeImageUrl'] ?? '',
      afterImageUrl: json['afterImageUrl'] ?? '',
      description: json['description'] ?? '',
      dayLabel: json['dayLabel'] ?? 'Day 1',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'dieticianId': dieticianId,
      'uploadedBy': uploadedBy,
      'uploadedByRole': uploadedByRole,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'description': description,
      'dayLabel': dayLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
