import 'package:dio/dio.dart';
import 'package:docwellnesdoc/core/session/session_service.dart';
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

  // Phase 9, P9-D3: shared across every ApiService() instance (constructed
  // fresh at each call site, same as docwellness-user) so concurrent
  // requests near token expiry de-dupe onto one /auth/refresh call instead
  // of each firing their own - a static field, not an instance field, is
  // what makes this shared across instances.
  static Future<void>? _refreshInFlight;

  /// Proactively refreshes the access token before it expires - replaces
  /// the Supabase SDK's own background auto-refresh (removed alongside the
  /// direct Supabase login/refresh calls - see docwellness-backend's
  /// /auth/refresh and AuthController.login). `force: false` (the
  /// pre-request check) is a no-op unless the token is actually close to
  /// expiring. `force: true` skips that check - used after a live 401 (see
  /// request() below), where the server has already decided the token is
  /// dead regardless of what our local clock thinks.
  Future<void> _refreshTokenIfNeeded({bool force = false}) {
    return _refreshInFlight ??= _doRefreshToken(force: force).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> _doRefreshToken({required bool force}) async {
    final session = SessionService.to;
    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return;

    if (!force) {
      final expiresAt = int.tryParse(session.tokenExpiresAt ?? '');
      if (expiresAt == null) return;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSeconds < expiresAt - 30) return;
    }

    try {
      final response = await _dio.request(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(method: 'POST', contentType: 'application/json'),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await session.setSession(
          token: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );
        // main.dart's `token` global is just a getter/setter bridge over
        // SessionService - the setSession() call above already persisted
        // it, but existing call sites that read the plain `token` global
        // directly (rather than through SessionService) need it updated
        // too.
        token = data['accessToken'];
      }
      // A non-200 here (dead refresh token) is left for the original
      // request to surface as its own 401.
    } catch (e) {
      // Network/timeout reaching /auth/refresh - proceed with the
      // (possibly stale) cached token rather than blocking the request
      // entirely.
      debugPrint('_refreshTokenIfNeeded failed (non-fatal): $e');
    }
  }

  Future<Response?> request({
    required String endPoint,
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool isRetryAfterRefresh = false,
  }) async {
    await _refreshTokenIfNeeded();
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
      // the pre-request check above only refreshes within ~30s of the
      // locally-cached expiry, so a request can still race a token that
      // just died server-side. One refresh-and-retry (guarded by
      // isRetryAfterRefresh so this can only happen once per original
      // call) covers that gap instead of the request failing outright.
      if (e.response?.statusCode == 401 && !isRetryAfterRefresh) {
        final tokenBeforeRefresh = SessionService.to.token;
        await _refreshTokenIfNeeded(force: true);
        final tokenAfterRefresh = SessionService.to.token;
        if (tokenAfterRefresh != null &&
            tokenAfterRefresh.isNotEmpty &&
            tokenAfterRefresh != tokenBeforeRefresh) {
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
}
