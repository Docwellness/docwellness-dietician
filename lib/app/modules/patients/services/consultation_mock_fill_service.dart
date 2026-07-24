import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/groq_dev_credentials.dart';

/// Dev-only helper: asks Groq's OpenAI-compatible chat completions API to
/// generate realistic mock answers for a consultation form, for the "magic
/// fill" button on QuestionsView (see kReleaseMode gate there - this
/// service is never reachable from a release build, but stays free of any
/// build-mode branching itself so it's simple to reason about/test).
class ConsultationMockFillService {
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  // Fast + good instruction-following for a small structured-JSON task;
  // no need for a heavier model just to invent plausible mock answers.
  static const _model = 'llama-3.3-70b-versatile';

  final Dio _dio = Dio();

  /// Returns a map of fieldId -> mock answer value (String for
  /// text/textarea/number/date/yesNo/singleChoice, a list of strings for
  /// multiChoice). Fields with type `file` are never asked for - nothing
  /// meaningful to mock there. Throws on any failure (network, bad API key,
  /// unparseable response) - the caller shows that as a toast.
  Future<Map<String, dynamic>> generateAnswers({
    required List<ConsultationFormField> fields,
    required String patientGender,
  }) async {
    if (kGroqApiKey.isEmpty) {
      throw StateError(
        'Groq API key not configured - see lib/groq_dev_credentials.example.dart',
      );
    }

    final askable = fields
        .where((f) => f.type != ConsultationFieldType.file)
        .toList();
    if (askable.isEmpty) return {};

    final fieldDescriptions = askable
        .map(
          (f) => {
            'fieldId': f.fieldId,
            'label': f.label,
            'type': f.type.apiValue,
            if (f.options.isNotEmpty) 'options': f.options,
          },
        )
        .toList();

    final prompt =
        '''
You are generating realistic MOCK answers for a dietician's patient-intake
consultation form, for internal app testing only (never shown to a real
patient). The patient is $patientGender.

Fields (JSON array, each has fieldId/label/type, and options if choice-based):
${jsonEncode(fieldDescriptions)}

Respond with ONLY a single JSON object mapping each fieldId to its answer.
Rules per type:
- text: a short, realistic string.
- textarea: 1-3 realistic sentences.
- number: a realistic numeric value as a plain string (no units).
- date: "YYYY-MM-DD", plausible for a consultation intake (e.g. a birth date
  should be a real adult age, a recent-event date should be in the past).
- yesNo: exactly "Yes" or "No".
- singleChoice: exactly one of the field's own "options" values, verbatim.
- multiChoice: a JSON array of 1 or more of the field's own "options"
  values, verbatim.
Keep answers mutually consistent (e.g. don't contradict yourself across
related fields). No commentary, no markdown - just the JSON object.
''';

    final response = await _dio.post(
      _endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $kGroqApiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You output only valid JSON objects, nothing else - no prose, no markdown fences.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.9,
      },
    );

    final content =
        response.data?['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw StateError('Groq returned an empty response');
    }

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Groq response was not a JSON object');
    }
    return decoded;
  }
}
