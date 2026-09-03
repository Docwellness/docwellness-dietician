import 'dart:convert';
import 'dart:math';

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
  // Good instruction-following for a small structured-JSON task. Was
  // 'llama-3.3-70b-versatile', which Groq retired (404 model_not_found) -
  // this is a currently-served model with json_object response support.
  static const _model = 'openai/gpt-oss-120b';

  // Given an identical field list + gender every time (same form, same
  // patient), the model tends to converge on the same "most likely" mock
  // persona even with a non-zero temperature - repeated taps produced near-
  // identical answers in practice. Rolling a random archetype into the
  // prompt each call, plus a random nonce the model is told to use only as
  // inspiration for variety, forces genuinely different output per tap
  // instead of relying on sampling alone.
  static const _archetypes = [
    'a busy working professional with an irregular schedule',
    'a college student living in a hostel/mess',
    'a homemaker managing a household with kids',
    'a retiree with a relatively sedentary routine',
    'a fitness enthusiast who trains regularly',
    'someone recovering from a recent illness/surgery',
    'a frequent traveler for work with inconsistent meal timings',
    'a night-shift worker with a flipped sleep schedule',
    'a new parent adjusting to disrupted sleep and routines',
    'someone managing a chronic condition (e.g. thyroid, PCOS, diabetes)',
  ];

  final Dio _dio = Dio();
  final Random _random = Random();

  /// Returns a map of fieldId -> mock answer value (String for
  /// text/textarea/number/date/yesNo/singleChoice, a list of strings for
  /// multiChoice). Fields with type `file` are never asked for - nothing
  /// meaningful to mock there. Throws on any failure (network, bad API key,
  /// unparseable response) - the caller shows that as a toast.
  ///
  /// [patientContext] carries whatever real basic/health info is already
  /// known about this patient (name, age, gender, height/weight/goal/etc.)
  /// so the generated answers stay grounded in - and consistent with - the
  /// actual person instead of reading as a generic template.
  Future<Map<String, dynamic>> generateAnswers({
    required List<ConsultationFormField> fields,
    required String patientGender,
    Map<String, dynamic>? patientContext,
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

    final archetype = _archetypes[_random.nextInt(_archetypes.length)];
    final nonce = _random.nextInt(1000000);

    final contextBlock = (patientContext == null || patientContext.isEmpty)
        ? 'None known yet - invent a plausible person from scratch.'
        : jsonEncode(patientContext);

    final prompt =
        '''
You are generating realistic MOCK answers for a dietician's patient-intake
consultation form, for internal app testing only (never shown to a real
patient). The patient is $patientGender.

Known real info about this patient already (treat as ground truth - stay
consistent with it, don't contradict it):
$contextBlock

For this generation, imagine the patient as: $archetype.
Variety token (ignore its value, just use it as a seed to make this
generation meaningfully different in details/wording from any other run -
different lifestyle specifics, different numbers, different phrasing):
$nonce

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
related fields, and stay consistent with the known real info above). No
commentary, no markdown - just the JSON object.
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
        'temperature': 1.0,
        'top_p': 0.95,
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
