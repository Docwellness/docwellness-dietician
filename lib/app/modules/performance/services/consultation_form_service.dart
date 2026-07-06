import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/widgets.dart';

class ConsultationFormService {
  final ApiService _api = ApiService();

  /// GET /api/dietician/consultation-form
  Future<List<ConsultationFormField>> getMyTemplate() async {
    try {
      final response = await _api.request(
        endPoint: '/consultation-form',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        final data = response.data['data'];
        final List rawFields = (data is Map && data['fields'] is List)
            ? List.from(data['fields'])
            : <dynamic>[];
        return rawFields
            .whereType<Map>()
            .map((e) => ConsultationFormField.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
    } catch (e) {
      debugPrint('getMyTemplate error: $e');
    }
    return <ConsultationFormField>[];
  }

  /// PUT /api/dietician/consultation-form
  Future<bool> upsertTemplate(List<ConsultationFormField> fields) async {
    try {
      final body = {
        'fields': fields
            .asMap()
            .entries
            .map((entry) => entry.value
                .copyWith(order: entry.key)
                .toJson())
            .toList(),
      };

      final response = await _api.request(
        endPoint: '/consultation-form',
        method: 'PUT',
        data: body,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true;
    } catch (e) {
      debugPrint('upsertTemplate error: $e');
      return false;
    }
  }
}
