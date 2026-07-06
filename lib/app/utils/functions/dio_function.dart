import 'package:dio/dio.dart';
import 'package:docwellnesdoc/main.dart';

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
          print(
            '🔑 Token attached: ${token != null ? "yes (${token!.substring(0, 20)}...)" : "NULL!"}',
          );
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
      print('📤 REQUEST => ${method.toUpperCase()} $endPoint');
      if (data is FormData) {
        print('📦 FormData fields: ${data.fields}');
        print('📦 FormData files: ${data.files.map((e) => e.key)}');
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

      print('✅ RESPONSE [${response.statusCode}] => ${response.data}');
      return response;
    } on DioException catch (e) {
      print("❌ Dio Error");
      print("URL: ${e.requestOptions.uri}");
      print("Status Code: ${e.response?.statusCode}");
      print("Response Data: ${e.response?.data}");
      print("Message: ${e.message}");
      return e.response;
    }
  }
}
