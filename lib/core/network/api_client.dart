import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'device_id_interceptor.dart';
import 'device_info_interceptor.dart';
import 'language_interceptor.dart';
import 'retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  late final DeviceIdInterceptor _deviceIdInterceptor;

  ApiClient({
    required String baseUrl,
    required PackageInfo packageInfo,
    FlutterSecureStorage? storage,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _deviceIdInterceptor = DeviceIdInterceptor(
      storage ?? const FlutterSecureStorage(),
    );

    _dio.interceptors.addAll([
      _deviceIdInterceptor,
      DeviceInfoInterceptor(packageInfo),
      LanguageInterceptor(),
      RetryInterceptor(dio: _dio),
    ]);
  }

  Dio get dio => _dio;

  /// Hesap silme akışı için: in-memory device ID cache'ini sıfırlar.
  /// Bir sonraki istek silinmiş SecureStorage'a düşer ve yeni UUID üretir
  /// (ya da storage henüz boşsa onboarding tamamlanana kadar geçici UUID).
  DeviceIdInterceptor get deviceIdInterceptor => _deviceIdInterceptor;
}
