import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/comparison/data/repositories/comparison_repository_impl.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';

class _MockDio extends Mock implements Dio {}

/// Faz 5.2: `DioException → AppError` eşlemesi ve null-gövde → ServerError
/// sözleşmesi ComparisonRepositoryImpl'e taşındı. Bu testler eşlemenin
/// korunduğunu ve parse hatalarının propagate edildiğini doğrular.
void main() {
  late _MockDio dio;
  late ComparisonRepositoryImpl repo;

  setUp(() {
    dio = _MockDio();
    repo = ComparisonRepositoryImpl(dio);
  });

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

  Map<String, dynamic> compareJson() => {
    'results': [
      {'rank': 1, 'calculation': calcJson()},
    ],
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

  Future<CompareResult> compare() => repo.compare(
    assetSymbols: const ['USDTRY', 'EURTRY'],
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    amount: Decimal.fromInt(10000),
    amountType: 'try',
  );

  group('ComparisonRepositoryImpl.compare', () {
    test('compare_success_returnsResult', () async {
      stubPost(okResponse(compareJson()));

      final result = await compare();

      expect(result.results, hasLength(1));
      expect(result.results.single.rank, 1);
      expect(result.results.single.calculation.assetSymbol, 'USDTRY');
    });

    test('compare_nullBody_throwsMalformedResponse', () async {
      stubPost(okResponse(null));

      await expectLater(compare(), throwsA(isA<MalformedResponseError>()));
    });

    test('compare_connectionError_throwsNoInternet', () async {
      stubPost(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(compare(), throwsA(isA<NoInternetError>()));
    });

    test('compare_unknownStatus404_throwsEndpointNeutralNotFound', () async {
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

      expect(compare(), throwsA(isA<NotFoundError>()));
    });

    test('compare_parseError_throwsMalformedResponse', () async {
      stubPost(okResponse({'results': 'not-a-list'}));

      await expectLater(compare(), throwsA(isA<MalformedResponseError>()));
    });

    test('compare_profitDirectionConflict_throwsMalformedResponse', () async {
      final payload = compareJson();
      final calculation =
          (payload['results'] as List<dynamic>).single['calculation']
              as Map<String, dynamic>;
      calculation['isProfit'] = false;
      stubPost(okResponse(payload));

      await expectLater(compare(), throwsA(isA<MalformedResponseError>()));
    });

    test('compare_decimalAmount_serializesCanonicalString', () async {
      stubPost(okResponse(compareJson()));

      await repo.compare(
        assetSymbols: const ['USDTRY', 'EURTRY'],
        buyDate: DateTime(2020),
        amount: Decimal.parse('10000.01'),
        amountType: 'try',
      );

      final captured =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  any(),
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['amount'], '10000.01');
    });
  });
}
