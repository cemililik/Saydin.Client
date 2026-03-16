import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';

void main() {
  const mapper = DioErrorMapper();

  DioException make(DioExceptionType type, {int? statusCode, dynamic data}) =>
      DioException(
        requestOptions: RequestOptions(),
        type: type,
        response: statusCode != null
            ? Response(
                requestOptions: RequestOptions(),
                statusCode: statusCode,
                data: data,
              )
            : null,
      );

  group('DioErrorMapper', () {
    test('connectionError → NoInternetError', () {
      final e = make(DioExceptionType.connectionError);
      expect(mapper.map(e), isA<NoInternetError>());
    });

    test('unknown type → NoInternetError', () {
      final e = make(DioExceptionType.unknown);
      expect(mapper.map(e), isA<NoInternetError>());
    });

    test('404 → PriceNotFoundError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 404);
      expect(mapper.map(e), isA<PriceNotFoundError>());
    });

    test('429 without resetAt → DailyLimitError with tomorrow midnight', () {
      final e = make(DioExceptionType.badResponse, statusCode: 429);
      final error = mapper.map(e);
      expect(error, isA<DailyLimitError>());
      final limit = error as DailyLimitError;
      expect(limit.resetAt.isAfter(DateTime.now()), isTrue);
    });

    test('429 with resetAt in response → DailyLimitError parses timestamp', () {
      final tomorrow = DateTime.utc(2026, 3, 17);
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 429,
        data: {
          'extensions': {'resetAt': tomorrow.toIso8601String()},
        },
      );
      final error = mapper.map(e) as DailyLimitError;
      expect(error.resetAt, equals(tomorrow));
    });

    test('500 → ServerError with statusCode', () {
      final e = make(DioExceptionType.badResponse, statusCode: 500);
      final error = mapper.map(e);
      expect(error, isA<ServerError>());
      expect((error as ServerError).statusCode, equals(500));
    });

    test('503 → ServerError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 503);
      expect(mapper.map(e), isA<ServerError>());
    });
  });
}
