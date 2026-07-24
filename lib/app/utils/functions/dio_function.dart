import 'package:dio/dio.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    // Always attach token to every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null && token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // AI_EXECUTION_PLAN.md Phase 7, P7-01 - was unconditionally
          // printing a slice of the raw JWT on every single request (in
          // release builds too - no kDebugMode gate) plus, below, full
          // request/response bodies, which can carry patient health data
          // in this app. Gated to debug builds, and the token itself is
          // never printed, even partially - only whether one is attached.
          if (kDebugMode) {
            debugPrint('🔑 Token attached: ${token != null && token!.isNotEmpty}');
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Response?> request({
    required String endPoint,
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 REQUEST => ${method.toUpperCase()} $endPoint');
        if (data is FormData) {
          debugPrint('📦 FormData fields: ${data.fields}');
          debugPrint('📦 FormData files: ${data.files.map((e) => e.key)}');
        }
      }

      // Merge any extra headers but ensure Authorization is set by interceptor
      final mergedHeaders = <String, dynamic>{};
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }

      final response = await _dio.request(
        endPoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: mergedHeaders),
      );

      if (kDebugMode) {
        debugPrint('✅ RESPONSE [${response.statusCode}] => ${response.data}');
      }
      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint("❌ Dio Error");
        debugPrint("URL: ${e.requestOptions.uri}");
        debugPrint("Status Code: ${e.response?.statusCode}");
        debugPrint("Response Data: ${e.response?.data}");
        debugPrint("Message: ${e.message}");
      }
      return e.response;
    }
  }
}
