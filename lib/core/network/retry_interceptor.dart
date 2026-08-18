import 'dart:io' show HttpDate, HttpException;
import 'dart:math';

import 'package:dio/dio.dart';

/// Ağ kaynaklı geçici hatalarda (connectionError, tüm timeout'lar) ve geçici
/// 5xx gateway hatalarında (502/503/504) isteği üstel geri çekilme
/// (exponential backoff) ile otomatik olarak yeniler.
///
/// Yalnızca idempotent HTTP metodlarına (GET, HEAD) uygulanır.
///
/// **Hangi hatalar yenilenir (F-05-09):**
/// - Bağlantı/timeout tipleri (`connectionError`, `connectionTimeout`,
///   `sendTimeout`, `receiveTimeout`) — geçici ağ sorunları.
/// - 502/503/504 — gateway/erişilemezlik/upstream-timeout (örn. backend'in
///   `external-api` 502'si ya da deploy/restart 503/504). Bunlar GEÇİCİdir.
///
/// **Hangileri YENİLENMEZ:** 500 (`internal-error` — genelde deterministik
/// sunucu hatası; retry yükü artırır, çözmez) ve tüm 4xx (domain/validation
/// hataları — deterministik). Yenilenmeyenler domain [AppError]'a dönüşür.
///
/// Sunucu uygun bir `Retry-After` header'ı döndürürse, normal backoff'tan daha
/// uzunsa bu süreye uyulur (en fazla 30 saniye). Request'in [CancelToken]'ı
/// bekleme sırasında iptal edilirse yeni bir HTTP isteği başlatılmaz.
///
/// **PII notu (F-14-16 / F-05-32):** Retry telemetrisi `debugPrint` ile
/// yazılmaz — release build'inde noise üretir ve `options.path` device
/// log'una ID/query token sızdırabilir. Sayısal retry metrikleri ileride
/// gerekirse Sentry breadcrumb'a (path scrub'lanmış) eklenir.
typedef RetryBackoff = Duration Function(int retryCount);
typedef RetryDelay =
    Future<bool> Function(Duration delay, CancelToken? cancelToken);
typedef RetryClock = DateTime Function();

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    RetryBackoff? backoff,
    RetryDelay? delay,
    RetryClock? clock,
  }) : _backoff = backoff ?? _defaultBackoff,
       _delay = delay ?? _waitForDelayOrCancellation,
       _clock = clock ?? DateTime.now;

  final Dio dio;
  final int maxRetries;
  final RetryBackoff _backoff;
  final RetryDelay _delay;
  final RetryClock _clock;

  static const _retryCountKey = '_retryCount';
  static const _maxServerRetryAfter = Duration(seconds: 30);

  static const _retryableTypes = {
    DioExceptionType.connectionError,
    DioExceptionType.sendTimeout,
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
    final delay = _effectiveDelay(err, retryCount);
    final waited = await _delay(delay, options.cancelToken);
    if (!waited || options.cancelToken?.isCancelled == true) {
      handler.next(
        options.cancelToken?.cancelError ??
            DioException.requestCancelled(
              requestOptions: options,
              reason: 'Request cancelled while waiting to retry.',
            ),
      );
      return;
    }

    options.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Duration _effectiveDelay(DioException err, int retryCount) {
    final backoff = _backoff(retryCount);
    final retryAfter = _retryAfter(err.response);
    if (retryAfter == null || retryAfter <= backoff) return backoff;
    return retryAfter;
  }

  Duration? _retryAfter(Response<dynamic>? response) {
    final value = response?.headers.value('retry-after')?.trim();
    if (value == null || value.isEmpty) return null;

    final seconds = int.tryParse(value);
    if (seconds != null) {
      if (seconds < 0) return null;
      return _capServerRetryAfter(Duration(seconds: seconds));
    }

    try {
      final duration = HttpDate.parse(value).difference(_clock());
      if (duration <= Duration.zero) return Duration.zero;
      return _capServerRetryAfter(duration);
    } on HttpException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// 2^attempt * 200ms, maksimum 2 saniye (+ küçük jitter).
  /// Constructor'daki [RetryBackoff] ile testlerde deterministik biçimde
  /// değiştirilebilir.
  static Duration _defaultBackoff(int attempt) {
    final base = min(200 * pow(2, attempt).toInt(), 2000);
    final jitter = _random.nextInt(100);
    return Duration(milliseconds: base + jitter);
  }

  static Duration _capServerRetryAfter(Duration duration) =>
      duration > _maxServerRetryAfter ? _maxServerRetryAfter : duration;

  /// Gecikme ile iptal future'ını yarıştırır. `false`, iptal nedeniyle yeni
  /// network request'i başlatılmaması gerektiğini bildirir.
  static Future<bool> _waitForDelayOrCancellation(
    Duration delay,
    CancelToken? cancelToken,
  ) async {
    if (cancelToken == null) {
      await Future<void>.delayed(delay);
      return true;
    }
    if (cancelToken.isCancelled) return false;

    return Future.any<bool>([
      Future<bool>.delayed(delay, () => true),
      cancelToken.whenCancel.then((_) => false),
    ]);
  }
}
