/// Field types supported by the custom consultation form.
enum ConsultationFieldType {
  text,
  textarea,
  number,
  date,
  yesNo,
  singleChoice,
  multiChoice,
  file,
}

extension ConsultationFieldTypeX on ConsultationFieldType {
  /// Backend string identifier for this field type.
  String get apiValue {
    switch (this) {
      case ConsultationFieldType.text:
        return 'text';
      case ConsultationFieldType.textarea:
        return 'textarea';
      case ConsultationFieldType.number:
        return 'number';
      case ConsultationFieldType.date:
        return 'date';
      case ConsultationFieldType.yesNo:
        return 'yesNo';
      case ConsultationFieldType.singleChoice:
        return 'singleChoice';
      case ConsultationFieldType.multiChoice:
        return 'multiChoice';
      case ConsultationFieldType.file:
        return 'file';
    }
  }

  /// Human-readable label for pickers.
  String get displayName {
    switch (this) {
      case ConsultationFieldType.text:
        return 'Short Text';
      case ConsultationFieldType.textarea:
        return 'Paragraph';
      case ConsultationFieldType.number:
        return 'Number';
      case ConsultationFieldType.date:
        return 'Date';
      case ConsultationFieldType.yesNo:
        return 'Yes / No';
      case ConsultationFieldType.singleChoice:
        return 'Single Choice';
      case ConsultationFieldType.multiChoice:
        return 'Multiple Choice';
      case ConsultationFieldType.file:
        return 'File Upload';
    }
  }

  bool get hasOptions =>
      this == ConsultationFieldType.singleChoice ||
      this == ConsultationFieldType.multiChoice;
}

ConsultationFieldType consultationFieldTypeFromApi(String? raw) {
  switch (raw) {
    case 'textarea':
      return ConsultationFieldType.textarea;
    case 'number':
      return ConsultationFieldType.number;
    case 'date':
      return ConsultationFieldType.date;
    case 'yesNo':
      return ConsultationFieldType.yesNo;
    case 'singleChoice':
      return ConsultationFieldType.singleChoice;
    case 'multiChoice':
      return ConsultationFieldType.multiChoice;
    case 'file':
      return ConsultationFieldType.file;
    case 'text':
    default:
      return ConsultationFieldType.text;
  }
}

/// Single field in a doctor's consultation form template.
class ConsultationFormField {
  final String fieldId;
  final ConsultationFieldType type;
  final String label;
  final List<String> options;
  final bool required;
  final int order;
  /// Groups consecutive fields under one section header on render (e.g.
  /// "3. Anthropometry & Weight History"). Empty = ungrouped.
  final String section;
  /// Visibility scope against the patient's gender.
  final String genderScope; // 'general' | 'female' | 'male'
  /// If set, this field only shows once the referenced field's current
  /// answer matches one of [dependsOnValues] (e.g. an "Other, please
  /// specify" follow-up field).
  final String? dependsOnFieldId;
  final List<String> dependsOnValues;

  ConsultationFormField({
    required this.fieldId,
    required this.type,
    required this.label,
    this.options = const [],
    this.required = false,
    this.order = 0,
    this.section = '',
    this.genderScope = 'general',
    this.dependsOnFieldId,
    this.dependsOnValues = const [],
  });

  ConsultationFormField copyWith({
    String? fieldId,
    ConsultationFieldType? type,
    String? label,
    List<String>? options,
    bool? required,
    int? order,
    String? section,
    String? genderScope,
    String? dependsOnFieldId,
    List<String>? dependsOnValues,
  }) {
    return ConsultationFormField(
      fieldId: fieldId ?? this.fieldId,
      type: type ?? this.type,
      label: label ?? this.label,
      options: options ?? this.options,
      required: required ?? this.required,
      order: order ?? this.order,
      section: section ?? this.section,
      genderScope: genderScope ?? this.genderScope,
      dependsOnFieldId: dependsOnFieldId ?? this.dependsOnFieldId,
      dependsOnValues: dependsOnValues ?? this.dependsOnValues,
    );
  }

  factory ConsultationFormField.fromJson(Map<String, dynamic> json) {
    final genderScope = (json['genderScope'] ?? 'general').toString();
    return ConsultationFormField(
      fieldId: (json['fieldId'] ?? '').toString(),
      type: consultationFieldTypeFromApi(json['type']?.toString()),
      label: (json['label'] ?? '').toString(),
      options: (json['options'] is List)
          ? List<String>.from(
              (json['options'] as List).map((e) => e.toString()),
            )
          : <String>[],
      required: json['required'] == true,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
      section: (json['section'] ?? '').toString(),
      genderScope: ['general', 'female', 'male'].contains(genderScope)
          ? genderScope
          : 'general',
      dependsOnFieldId: json['dependsOnFieldId']?.toString(),
      dependsOnValues: (json['dependsOnValues'] is List)
          ? List<String>.from(
              (json['dependsOnValues'] as List).map((e) => e.toString()),
            )
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'fieldId': fieldId,
        'type': type.apiValue,
        'label': label,
        'options': options,
        'required': required,
        'order': order,
        'section': section,
        'genderScope': genderScope,
        'dependsOnFieldId': dependsOnFieldId,
        'dependsOnValues': dependsOnValues,
      };
}
