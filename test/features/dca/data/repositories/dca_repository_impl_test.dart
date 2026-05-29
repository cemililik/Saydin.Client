import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/dca/data/repositories/dca_repository_impl.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';

class _MockDio extends Mock implements Dio {}

/// Faz 5.2: `DioException → AppError` eşlemesi ve null-gövde → ServerError
/// sözleşmesi DcaRepositoryImpl'e taşındı. Bu testler eşlemenin korunduğunu ve
/// parse hatalarının yutulmayıp propagate edildiğini doğrular.
void main() {
  late _MockDio dio;
  late DcaRepositoryImpl repo;

  setUp(() {
    dio = _MockDio();
    repo = DcaRepositoryImpl(dio);
  });

  Map<String, dynamic> dcaJson() => {
    'assetSymbol': 'USDTRY',
    'assetDisplayName': 'Dolar/TL',
    'startDate': '2020-01-01',
    'endDate': '2021-01-01',
    'period': 'monthly',
    'periodicAmount': 1000.0,
    'totalPurchases': 12,
    'totalInvestedTry': 12000.0,
    'currentValueTry': 15000.0,
    'profitLossTry': 3000.0,
    'profitLossPercent': 25.0,
    'isProfit': true,
    'averageCostPerUnit': 5.5,
    'totalUnitsAcquired': 2181.81,
    'currentUnitPrice': 6.8,
  };

  Response<Map<String, dynamic>> okResponse(Map<String, dynamic>? data) =>
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: data,
      );

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

  Future<DcaResult> calc() => repo.calculate(
    assetSymbol: 'USDTRY',
    startDate: DateTime(2020, 1, 1),
    endDate: DateTime(2021, 1, 1),
    periodicAmount: 1000,
    period: 'monthly',
    amountType: 'try',
  );

  group('DcaRepositoryImpl.calculate', () {
    test('calculate_success_returnsResult', () async {
      stubPost(okResponse(dcaJson()));

      final result = await calc();

      expect(result.assetSymbol, 'USDTRY');
      expect(result.totalPurchases, 12);
      expect(result.currentValueTry, Decimal.parse('15000.0'));
    });

    test('calculate_nullBody_throwsMalformedResponse', () async {
      stubPost(okResponse(null));

      // F-07-08: 2xx + boş gövde → MalformedResponseError.
      await expectLater(calc(), throwsA(isA<MalformedResponseError>()));
    });

    test('calculate_connectionError_throwsNoInternet', () async {
      stubPost(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(calc(), throwsA(isA<NoInternetError>()));
    });

    test('calculate_status404_throwsPriceNotFound', () async {
      stubPost(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 404,
          ),
        ),
      );

      expect(calc(), throwsA(isA<PriceNotFoundError>()));
    });

    test('calculate_parseError_propagatesNotSwallowed', () async {
      // Bozuk para alanı → FormatException; `on DioException` yakalamaz, ham
      // hata propagate olur (AppError'a sarılmaz — sözleşme L-1).
      stubPost(okResponse({...dcaJson(), 'currentValueTry': 'not-a-number'}));

      await expectLater(
        calc(),
        throwsA(allOf(isA<FormatException>(), isNot(isA<AppError>()))),
      );
    });
  });
}
