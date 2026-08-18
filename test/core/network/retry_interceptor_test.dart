import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/retry_interceptor.dart';

class _MockDio extends Mock implements Dio {}

/// `handler.next`/`resolve` çağrılarını kaydeden sahte handler. Interceptor
/// handler'ı await etmez; bu yüzden completer'ı tetiklememek sorun değil.
class _FakeErrorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  DioException? nextError;

  @override
  void next(DioException err) {
    nextCalled = true;
    nextError = err;
  }

  @override
  void resolve(Response<dynamic> response) => resolveCalled = true;
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  late _MockDio dio;
  late RetryInterceptor interceptor;

  setUp(() {
    dio = _MockDio();
    interceptor = RetryInterceptor(
      dio: dio,
      maxRetries: 2,
      backoff: (_) => Duration.zero,
    );
  });

  late RequestOptions lastOptions;

  DioException error({
    required DioExceptionType type,
    String method = 'GET',
    int? statusCode,
    int? retryCount,
    Headers? headers,
    CancelToken? cancelToken,
  }) {
    final options = RequestOptions(
      path: '/v1/assets',
      method: method,
      cancelToken: cancelToken,
    );
    if (retryCount != null) options.extra['_retryCount'] = retryCount;
    lastOptions = options;
    return DioException(
      requestOptions: options,
      type: type,
      response: statusCode != null
          ? Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
              headers: headers ?? Headers(),
            )
          : null,
    );
  }

  void stubFetchSuccess() {
    when(() => dio.fetch<dynamic>(any())).thenAnswer(
      (inv) async => Response<dynamic>(
        requestOptions: inv.positionalArguments.first as RequestOptions,
        statusCode: 200,
      ),
    );
  }

  group('retries (idempotent GET)', () {
    // L-5: bağlantı + timeout sınıfının tamamı yeniden denenir.
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionTimeout,
    ]) {
      test('${type.name}_isRetried', () async {
        stubFetchSuccess();
        final handler = _FakeErrorHandler();
        await interceptor.onError(error(type: type), handler);
        verify(() => dio.fetch<dynamic>(any())).called(1);
        expect(handler.resolveCalled, isTrue);
      });
    }

    for (final status in [502, 503, 504]) {
      test('badResponse_${status}_isRetried (F-05-09)', () async {
        stubFetchSuccess();
        final handler = _FakeErrorHandler();
        await interceptor.onError(
          error(type: DioExceptionType.badResponse, statusCode: status),
          handler,
        );
        verify(() => dio.fetch<dynamic>(any())).called(1);
        expect(handler.resolveCalled, isTrue);
      });
    }
  });

  group('does NOT retry', () {
    test('500_isNotRetried (deterministik internal-error)', () async {
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(type: DioExceptionType.badResponse, statusCode: 500),
        handler,
      );
      verifyNever(() => dio.fetch<dynamic>(any()));
      expect(handler.nextCalled, isTrue);
    });

    test('404_isNotRetried (domain hatası)', () async {
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(type: DioExceptionType.badResponse, statusCode: 404),
        handler,
      );
      verifyNever(() => dio.fetch<dynamic>(any()));
      expect(handler.nextCalled, isTrue);
    });

    test('503_POST_isNotRetried (idempotent değil)', () async {
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(
          type: DioExceptionType.badResponse,
          method: 'POST',
          statusCode: 503,
        ),
        handler,
      );
      verifyNever(() => dio.fetch<dynamic>(any()));
      expect(handler.nextCalled, isTrue);
    });
  });

  // L-5: tükenme, retry-then-fail ve sayaç doğrulaması.
  group('edge cases', () {
    test('maxRetries_reached_doesNotRetryAgain (sonsuz retry yok)', () async {
      final handler = _FakeErrorHandler();
      // _retryCount == maxRetries (2) → tekrar denenmez.
      await interceptor.onError(
        error(type: DioExceptionType.connectionError, retryCount: 2),
        handler,
      );
      verifyNever(() => dio.fetch<dynamic>(any()));
      expect(handler.nextCalled, isTrue);
    });

    test('retry_thenFetchFails_callsNextNotResolve', () async {
      when(() => dio.fetch<dynamic>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/assets'),
          type: DioExceptionType.connectionError,
        ),
      );
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(type: DioExceptionType.connectionError),
        handler,
      );
      expect(handler.nextCalled, isTrue);
      expect(handler.resolveCalled, isFalse);
    });

    test('successfulRetry_incrementsRetryCount', () async {
      stubFetchSuccess();
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(type: DioExceptionType.connectionError),
        handler,
      );
      expect(lastOptions.extra['_retryCount'], 1);
    });

    test('Retry-After seconds normal backofftan uzunsa uygulanır', () async {
      Duration? observedDelay;
      interceptor = RetryInterceptor(
        dio: dio,
        backoff: (_) => const Duration(milliseconds: 100),
        delay: (delay, _) async {
          observedDelay = delay;
          return true;
        },
      );
      stubFetchSuccess();

      await interceptor.onError(
        error(
          type: DioExceptionType.badResponse,
          statusCode: 503,
          headers: Headers.fromMap({
            'retry-after': ['3'],
          }),
        ),
        _FakeErrorHandler(),
      );

      expect(observedDelay, const Duration(seconds: 3));
    });

    test(
      'HTTP-date Retry-After parse edilir ve güvenli üst sınıra kesilir',
      () async {
        Duration? observedDelay;
        final now = DateTime.utc(2026, 8, 18, 12);
        interceptor = RetryInterceptor(
          dio: dio,
          backoff: (_) => Duration.zero,
          clock: () => now,
          delay: (delay, _) async {
            observedDelay = delay;
            return true;
          },
        );
        stubFetchSuccess();

        await interceptor.onError(
          error(
            type: DioExceptionType.badResponse,
            statusCode: 503,
            headers: Headers.fromMap({
              'retry-after': [
                HttpDate.format(now.add(const Duration(days: 1))),
              ],
            }),
          ),
          _FakeErrorHandler(),
        );

        expect(observedDelay, const Duration(seconds: 30));
      },
    );

    test(
      'geçersiz Retry-After enjekte edilmiş normal backoffa düşer',
      () async {
        Duration? observedDelay;
        const backoff = Duration(milliseconds: 250);
        interceptor = RetryInterceptor(
          dio: dio,
          backoff: (_) => backoff,
          delay: (delay, _) async {
            observedDelay = delay;
            return true;
          },
        );
        stubFetchSuccess();

        await interceptor.onError(
          error(
            type: DioExceptionType.badResponse,
            statusCode: 503,
            headers: Headers.fromMap({
              'retry-after': ['invalid'],
            }),
          ),
          _FakeErrorHandler(),
        );

        expect(observedDelay, backoff);
      },
    );

    test(
      'CancelToken retry beklemesini keser ve yeni request başlatmaz',
      () async {
        final token = CancelToken();
        interceptor = RetryInterceptor(
          dio: dio,
          backoff: (_) => const Duration(seconds: 1),
          delay: (_, cancelToken) => cancelToken!.whenCancel.then((_) => false),
        );
        final handler = _FakeErrorHandler();

        final retry = interceptor.onError(
          error(type: DioExceptionType.connectionError, cancelToken: token),
          handler,
        );
        token.cancel('route disposed');
        await retry;

        verifyNever(() => dio.fetch<dynamic>(any()));
        expect(handler.nextCalled, isTrue);
        expect(handler.nextError?.type, DioExceptionType.cancel);
      },
    );
  });
}
