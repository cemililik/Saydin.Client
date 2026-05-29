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

  @override
  void next(DioException err) => nextCalled = true;

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
    interceptor = RetryInterceptor(dio: dio, maxRetries: 2);
  });

  DioException error({
    required DioExceptionType type,
    String method = 'GET',
    int? statusCode,
  }) {
    final options = RequestOptions(path: '/v1/assets', method: method);
    return DioException(
      requestOptions: options,
      type: type,
      response: statusCode != null
          ? Response<dynamic>(requestOptions: options, statusCode: statusCode)
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
    test('connectionError_isRetried', () async {
      stubFetchSuccess();
      final handler = _FakeErrorHandler();
      await interceptor.onError(
        error(type: DioExceptionType.connectionError),
        handler,
      );
      verify(() => dio.fetch<dynamic>(any())).called(1);
      expect(handler.resolveCalled, isTrue);
    });

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
}
