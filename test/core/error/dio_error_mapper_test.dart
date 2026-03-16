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
    test('map_connectionError_returnsNoInternetError', () {
      final e = make(DioExceptionType.connectionError);
      expect(mapper.map(e), isA<NoInternetError>());
    });

    test('map_unknownType_returnsNoInternetError', () {
      final e = make(DioExceptionType.unknown);
      expect(mapper.map(e), isA<NoInternetError>());
    });

    test('map_404_returnsPriceNotFoundError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 404);
      expect(mapper.map(e), isA<PriceNotFoundError>());
    });

    test(
      'map_429WithoutResetAt_returnsDailyLimitErrorWithTomorrowUtcMidnight',
      () {
        final e = make(DioExceptionType.badResponse, statusCode: 429);
        final error = mapper.map(e) as DailyLimitError;

        final nowUtc = DateTime.now().toUtc();
        final tomorrowUtc = nowUtc.add(const Duration(days: 1));
        final expectedDate = DateTime.utc(
          tomorrowUtc.year,
          tomorrowUtc.month,
          tomorrowUtc.day,
        );

        expect(error.resetAt, equals(expectedDate));
      },
    );

    test('map_429WithResetAt_returnsDailyLimitErrorWithParsedTimestamp', () {
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

    test('map_500_returnsServerErrorWithStatusCode', () {
      final e = make(DioExceptionType.badResponse, statusCode: 500);
      final error = mapper.map(e) as ServerError;
      expect(error.statusCode, equals(500));
    });

    test('map_503_returnsServerError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 503);
      expect(mapper.map(e), isA<ServerError>());
    });
  });
}
