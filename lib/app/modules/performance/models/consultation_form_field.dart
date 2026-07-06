/// Field types supported by the custom consultation form.
enum ConsultationFieldType {
  text,
  textarea,
  number,
  date,
  yesNo,
  singleChoice,
  multiChoice,
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

  ConsultationFormField({
    required this.fieldId,
    required this.type,
    required this.label,
    this.options = const [],
    this.required = false,
    this.order = 0,
  });

  ConsultationFormField copyWith({
    String? fieldId,
    ConsultationFieldType? type,
    String? label,
    List<String>? options,
    bool? required,
    int? order,
  }) {
    return ConsultationFormField(
      fieldId: fieldId ?? this.fieldId,
      type: type ?? this.type,
      label: label ?? this.label,
      options: options ?? this.options,
      required: required ?? this.required,
      order: order ?? this.order,
    );
  }

  factory ConsultationFormField.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() => {
        'fieldId': fieldId,
        'type': type.apiValue,
        'label': label,
        'options': options,
        'required': required,
        'order': order,
      };
}
