import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/what_if/data/repositories/what_if_repository_impl.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

class _MockDio extends Mock implements Dio {}

/// Faz 5.2'nin özü: `DioException → AppError` eşlemesi BLoC'tan repository
/// katmanına taşındı. Bu testler o eşlemenin (NoInternet / PriceNotFound /
/// ServerError) ve null-gövde → ServerError sözleşmesinin korunduğunu;
/// beklenmedik parse hatalarının ise `on DioException` tarafından yutulmayıp
/// üst katmana propagate edildiğini doğrular (regresyon kalkanı).
void main() {
  late _MockDio dio;
  late WhatIfRepositoryImpl repo;

  setUp(() {
    dio = _MockDio();
    repo = WhatIfRepositoryImpl(dio);
  });

  // ── Fixtures ──────────────────────────────────────────────────────────────

  Map<String, dynamic> calcJson() => {
    'assetSymbol': 'USDTRY',
    'assetDisplayName': 'Dolar/TL',
    'buyDate': '2020-01-01',
    'sellDate': '2021-01-01',
    'buyPrice': 5.95,
    'sellPrice': 8.50,
    'unitsAcquired': 1680.672269,
    'initialValueTry': 10000.0,
    'finalValueTry': 14285.71,
    'profitLossTry': 4285.71,
    'profitLossPercent': 42.86,
    'isProfit': true,
  };

  Response<Map<String, dynamic>> okResponse(Map<String, dynamic>? data) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: data,
      );

  DioException connectionError() => DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: DioExceptionType.connectionError,
  );

  DioException badResponse(int status) => DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: status,
    ),
  );

  void stubGet(Object answer) {
    final stub = when(() => dio.get<Map<String, dynamic>>(any()));
    if (answer is DioException) {
      stub.thenThrow(answer);
    } else {
      stub.thenAnswer((_) async => answer as Response<Map<String, dynamic>>);
    }
  }

  void stubPost(Object answer) {
    final stub = when(
      () => dio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    );
    if (answer is DioException) {
      stub.thenThrow(answer);
    } else {
      stub.thenAnswer((_) async => answer as Response<Map<String, dynamic>>);
    }
  }

  Future<WhatIfResult> calc() => repo.calculate(
    assetSymbol: 'USDTRY',
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    amount: 10000,
    amountType: 'try',
  );

  // ── getAssets ─────────────────────────────────────────────────────────────

  group('WhatIfRepositoryImpl.getAssets', () {
    test('getAssets_success_returnsAssets', () async {
      stubGet(
        okResponse({
          'assets': [
            {'symbol': 'USDTRY', 'displayName': 'Dolar/TL', 'category': 'fx'},
          ],
        }),
      );

      final assets = await repo.getAssets();

      expect(assets, hasLength(1));
      expect(assets.single.symbol, 'USDTRY');
    });

    test('getAssets_nullBody_returnsEmptyList', () async {
      stubGet(okResponse(null));

      expect(await repo.getAssets(), isEmpty);
    });

    test('getAssets_connectionError_throwsNoInternet', () async {
      stubGet(connectionError());

      expect(repo.getAssets(), throwsA(isA<NoInternetError>()));
    });
  });

  // ── calculate ───────────────────────────────────────────────────────────

  group('WhatIfRepositoryImpl.calculate', () {
    test('calculate_success_returnsResult', () async {
      stubPost(okResponse(calcJson()));

      final result = await calc();

      expect(result.assetSymbol, 'USDTRY');
      expect(result.finalValueTry, Decimal.parse('14285.71'));
    });

    test('calculate_nullBody_throwsServerError', () async {
      stubPost(okResponse(null));

      await expectLater(
        calc(),
        throwsA(
          isA<ServerError>().having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('calculate_connectionError_throwsNoInternet', () async {
      stubPost(connectionError());

      expect(calc(), throwsA(isA<NoInternetError>()));
    });

    test('calculate_status404_throwsPriceNotFound', () async {
      stubPost(badResponse(404));

      expect(calc(), throwsA(isA<PriceNotFoundError>()));
    });

    test('calculate_status500_throwsServerError', () async {
      stubPost(badResponse(500));

      expect(
        calc(),
        throwsA(
          isA<ServerError>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('calculate_parseError_propagatesNotSwallowed', () async {
      // Bozuk para alanı → FormatException. `on DioException` bunu YAKALAMAMALI;
      // ham hata üst katmana çıkar (AppError'a sarılmaz — sözleşme L-1).
      stubPost(okResponse({...calcJson(), 'finalValueTry': 'not-a-number'}));

      await expectLater(
        calc(),
        throwsA(allOf(isA<FormatException>(), isNot(isA<AppError>()))),
      );
    });
  });

  // ── calculateReverse ────────────────────────────────────────────────────

  group('WhatIfRepositoryImpl.calculateReverse', () {
    Future<void> reverse() => repo.calculateReverse(
      assetSymbol: 'USDTRY',
      buyDate: DateTime(2020, 1, 1),
      targetAmount: 1000,
      targetAmountType: 'try',
    );

    test('calculateReverse_nullBody_throwsServerError', () async {
      stubPost(okResponse(null));

      expect(reverse(), throwsA(isA<ServerError>()));
    });

    test('calculateReverse_connectionError_throwsNoInternet', () async {
      stubPost(connectionError());

      expect(reverse(), throwsA(isA<NoInternetError>()));
    });
  });
}
