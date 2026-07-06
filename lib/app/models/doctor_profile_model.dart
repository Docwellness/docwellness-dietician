class DoctorProfileModel {
  final String fullName;
  final DateTime? dateOfBirth;
  final String profileImage;
  final String gender;
  final String specialization;
  final int experience;
  final String qualification;
  final String bio;

  DoctorProfileModel({
    required this.fullName,
    this.dateOfBirth,
    required this.profileImage,
    required this.gender,
    required this.specialization,
    required this.experience,
    required this.qualification,
    required this.bio,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      profileImage: json['profileImage'] ?? '',
      gender: json['gender'] ?? '',
      specialization: json['specialization'] ?? '',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      qualification: json['qualification'] ?? '',
      bio: json['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'specialization': specialization,
      'experience': experience,
      'qualification': qualification,
      'bio': bio,
    };
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}
