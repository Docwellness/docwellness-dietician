import 'package:dio/dio.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    bool isRetryAfterRefresh = false,
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
      // A 401 here usually means the access token expired mid-session -
      // Supabase auto-refreshes it in the background, but Android can
      // suspend that timer while the app is backgrounded, so the copy in
      // SessionService can still be stale at the moment a request goes out.
      // One refresh-and-retry covers that gap instead of the request (and
      // every one after it, since nothing else re-triggers a refresh)
      // failing until the app is killed and relaunched.
      if (e.response?.statusCode == 401 && !isRetryAfterRefresh) {
        final refreshedToken = await _tryRefreshToken();
        if (refreshedToken != null) {
          return request(
            endPoint: endPoint,
            method: method,
            data: data,
            queryParameters: queryParameters,
            headers: headers,
            isRetryAfterRefresh: true,
          );
        }
      }

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

  Future<String?> _tryRefreshToken() async {
    try {
      final res = await Supabase.instance.client.auth.refreshSession();
      final session = res.session;
      if (session != null) {
        token = session.accessToken;
        return session.accessToken;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Token refresh failed: $e');
    }
    return null;
  }
}
