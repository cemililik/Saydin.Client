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

    // F-05-10: `unknown` artık NoInternet'e DEĞİL UnknownError'a eşlenir —
    // `unknown` bağlantı yokluğu değil, istek sırasında beklenmeyen bir hatadır.
    test('map_unknownType_returnsUnknownError', () {
      final e = make(DioExceptionType.unknown);
      expect(mapper.map(e), isA<UnknownError>());
    });

    test('map_404_returnsPriceNotFoundError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 404);
      expect(mapper.map(e), isA<PriceNotFoundError>());
    });

    test(
      'map_429WithoutResetAt_returnsDailyLimitErrorWithTomorrowUtcMidnight',
      () {
        DateTime tomorrowMidnight(DateTime d) {
          final t = d.toUtc().add(const Duration(days: 1));
          return DateTime.utc(t.year, t.month, t.day);
        }

        // UTC gece yarısı straddle'ında flaky olmasın: map() kendi now()'unu
        // kullanır; test now()'u farklı güne düşerse her iki olasılığı kabul et.
        final before = DateTime.now();
        final error =
            mapper.map(make(DioExceptionType.badResponse, statusCode: 429))
                as DailyLimitError;
        final after = DateTime.now();

        expect(
          error.resetAt,
          anyOf(tomorrowMidnight(before), tomorrowMidnight(after)),
        );
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

    // F-05-12: non-Map gövde (HTML/string/List/null) `[]` erişiminde
    // NoSuchMethodError atmamalı; güvenle ServerError/DailyLimitError'a düşmeli.
    test('map_422WithStringBody_returnsServerErrorNoThrow', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 422,
        data: '<html>504 Gateway Timeout</html>',
      );
      final error = mapper.map(e) as ServerError;
      expect(error.statusCode, 422);
    });

    test('map_429WithListBody_returnsDailyLimitErrorNoThrow', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 429,
        data: const ['unexpected', 'list'],
      );
      expect(mapper.map(e), isA<DailyLimitError>());
    });

    test('map_422ScenarioLimit_validMap_returnsScenarioLimitError', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 422,
        data: {
          'type': 'https://saydin.app/errors/scenario-limit-exceeded',
          'extensions': {'limit': 10},
        },
      );
      final error = mapper.map(e) as ScenarioLimitError;
      expect(error.limit, 10);
    });

    test('map_422ScenarioLimit_wrongTypeLimit_fallsBackTo5', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 422,
        data: {
          'type': 'https://saydin.app/errors/scenario-limit-exceeded',
          'extensions': {'limit': 'not-a-number'},
        },
      );
      final error = mapper.map(e) as ScenarioLimitError;
      expect(error.limit, 5);
    });

    // F-05-11: backend RFC-7807 ProblemDetails + ASP.NET `[JsonExtensionData]`
    // → extensions DÜZ (top-level) serialize edilir. Mapper hem düz hem nested
    // okur; aşağıdaki testler gerçek (düz) backend şeklini doğrular.
    test('map_typeAssetNotFound_returnsAssetNotFoundError', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 404,
        data: {'type': 'https://saydin.app/errors/asset-not-found'},
      );
      expect(mapper.map(e), isA<AssetNotFoundError>());
    });

    test('map_typePriceNotFound_returnsPriceNotFoundError', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 404,
        data: {'type': 'https://saydin.app/errors/price-not-found'},
      );
      expect(mapper.map(e), isA<PriceNotFoundError>());
    });

    test('map_scenarioLimit_flatLimit_readsTopLevel', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 422,
        data: {
          'type': 'https://saydin.app/errors/scenario-limit-exceeded',
          'status': 422,
          'limit': 10, // ASP.NET düzleştirilmiş extension
        },
      );
      final error = mapper.map(e) as ScenarioLimitError;
      expect(error.limit, 10);
    });

    test('map_dailyLimit_flatResetAt_readsTopLevel', () {
      final reset = DateTime.utc(2026, 5, 30);
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 429,
        data: {
          'type': 'https://saydin.app/errors/daily-limit-exceeded',
          'status': 429,
          'resetAt': reset.toIso8601String(), // düzleştirilmiş
        },
      );
      final error = mapper.map(e) as DailyLimitError;
      expect(error.resetAt, equals(reset));
    });

    test('map_404WithoutType_fallsBackToPriceNotFound', () {
      final e = make(
        DioExceptionType.badResponse,
        statusCode: 404,
        data: <String, dynamic>{},
      );
      expect(mapper.map(e), isA<PriceNotFoundError>());
    });

    test('map_502_returnsServerError', () {
      final e = make(DioExceptionType.badResponse, statusCode: 502);
      final error = mapper.map(e) as ServerError;
      expect(error.statusCode, 502);
    });
  });
}
