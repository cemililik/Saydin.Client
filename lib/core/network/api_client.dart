import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_id_interceptor.dart';
import 'language_interceptor.dart';
import 'retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required String baseUrl, FlutterSecureStorage? storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      DeviceIdInterceptor(storage ?? const FlutterSecureStorage()),
      LanguageInterceptor(),
      RetryInterceptor(dio: _dio),
    ]);
  }

  Dio get dio => _dio;
}
