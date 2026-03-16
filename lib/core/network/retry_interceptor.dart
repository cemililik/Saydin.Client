import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ağ kaynaklı geçici hatalarda (connectionError, receiveTimeout) isteği
/// üstel geri çekilme (exponential backoff) ile otomatik olarak yeniler.
///
/// Yalnızca idempotent HTTP metodlarına (GET, HEAD) uygulanır.
/// 4xx veya 5xx yanıtlar yenilenmez — bunlar domain hatasına dönüştürülür.
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

  static const _idempotentMethods = {'GET', 'HEAD'};

  static final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();

    if (!_retryableTypes.contains(err.type) ||
        !_idempotentMethods.contains(method)) {
      return handler.next(err);
    }

    final retryCount = (options.extra[_retryCountKey] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    final delay = _backoffDelay(retryCount);
    debugPrint(
      '[RetryInterceptor] Retrying (attempt ${retryCount + 1}/$maxRetries) '
      '${options.method} ${options.path} after ${delay.inMilliseconds}ms',
    );
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
