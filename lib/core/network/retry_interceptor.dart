import 'dart:math';

import 'package:dio/dio.dart';

/// Ağ kaynaklı geçici hatalarda (connectionError, receiveTimeout) ve geçici
/// 5xx gateway hatalarında (502/503/504) isteği üstel geri çekilme
/// (exponential backoff) ile otomatik olarak yeniler.
///
/// Yalnızca idempotent HTTP metodlarına (GET, HEAD) uygulanır.
///
/// **Hangi hatalar yenilenir (F-05-09):**
/// - Bağlantı/timeout tipleri (`connectionError`, `receiveTimeout`,
///   `connectionTimeout`) — geçici ağ sorunları.
/// - 502/503/504 — gateway/erişilemezlik/upstream-timeout (örn. backend'in
///   `external-api` 502'si ya da deploy/restart 503/504). Bunlar GEÇİCİdir.
///
/// **Hangileri YENİLENMEZ:** 500 (`internal-error` — genelde deterministik
/// sunucu hatası; retry yükü artırır, çözmez) ve tüm 4xx (domain/validation
/// hataları — deterministik). Yenilenmeyenler domain [AppError]'a dönüşür.
///
/// **PII notu (F-14-16 / F-05-32):** Retry telemetrisi `debugPrint` ile
/// yazılmaz — release build'inde noise üretir ve `options.path` device
/// log'una ID/query token sızdırabilir. Sayısal retry metrikleri ileride
/// gerekirse Sentry breadcrumb'a (path scrub'lanmış) eklenir.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 2});

  final Dio dio;
  final int maxRetries;

  static const _retryCountKey = '_retryCount';

  static const _retryableTypes = {
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionTimeout,
  };

  /// Geçici (transient) 5xx — yeniden denemeye değer. 500 kasıtlı olarak
  /// dışarıda: `internal-error` deterministik bir sunucu hatasıdır.
  static const _retryableStatusCodes = {502, 503, 504};

  static const _idempotentMethods = {'GET', 'HEAD'};

  static final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();

    if (!_idempotentMethods.contains(method) || !_shouldRetry(err)) {
      return handler.next(err);
    }

    final retryCount = (options.extra[_retryCountKey] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    return _retry(err, handler, options, retryCount);
  }

  /// Hata yeniden denemeye uygun mu? Geçici ağ/timeout tipleri VEYA geçici
  /// 5xx (502/503/504). 500 ve 4xx deterministik → yenilenmez.
  bool _shouldRetry(DioException err) {
    if (_retryableTypes.contains(err.type)) return true;
    if (err.type == DioExceptionType.badResponse) {
      return _retryableStatusCodes.contains(err.response?.statusCode);
    }
    return false;
  }

  Future<void> _retry(
    DioException err,
    ErrorInterceptorHandler handler,
    RequestOptions options,
    int retryCount,
  ) async {
    final delay = _backoffDelay(retryCount);
    await Future<void>.delayed(delay);

    options.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// 2^attempt * 200ms, maksimum 2 saniye (+ küçük jitter)
  static Duration _backoffDelay(int attempt) {
    final base = min(200 * pow(2, attempt).toInt(), 2000);
    final jitter = _random.nextInt(100);
    return Duration(milliseconds: base + jitter);
  }
}
