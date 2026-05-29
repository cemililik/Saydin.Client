import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/scenarios/data/repositories/scenarios_repository_impl.dart';

class _MockDio extends Mock implements Dio {}

/// Bozuk satır raporlamasını (fire-and-forget) saymak için fake reporter —
/// gerçek `ErrorReporter` Sentry init'siz no-op olur, fake çağrı sayar.
class _FakeErrorReporter implements ErrorReporter {
  final reports = <Object>[];

  @override
  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, Object?>? extras,
  }) async {
    reports.add(exception);
  }

  @override
  Future<void> recordAction(
    String action, {
    String? category,
    Map<String, Object?>? data,
  }) async {}

  @override
  Future<void> addBreadcrumb(String message, {String? category}) async {}

  @override
  Future<void> clearScope() async {}
}

/// Faz 5.2 + F-11-03: Dio→AppError eşlemesi VE silme idempotency'si (404 =
/// zaten yok → sessiz başarı) BLoC'tan repository katmanına taşındı. Bu dosya,
/// scenarios_bloc_test.dart'ın atıfta bulunduğu "repo seviyesi 404 davranışı"
/// doğrulamasını sağlar (önceden eksik olan dangling reference'ı kapatır).
void main() {
  late _MockDio dio;
  late _FakeErrorReporter reporter;
  late ScenariosRepositoryImpl repo;

  setUp(() {
    dio = _MockDio();
    reporter = _FakeErrorReporter();
    repo = ScenariosRepositoryImpl(dio, reporter: reporter);
  });

  Map<String, dynamic> scenarioJson({String id = 'abc-123'}) => {
    'id': id,
    'type': 'what_if',
    'assetSymbol': 'USDTRY',
    'assetDisplayName': 'Dolar/TL',
    'buyDate': '2020-03-01',
    'sellDate': '2021-01-01',
    'amount': 10000,
    'amountType': 'try',
    'createdAt': '2026-01-01T12:00:00Z',
  };

  DioException dioError(int status) => DioException(
    requestOptions: RequestOptions(path: '/v1/scenarios'),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/v1/scenarios'),
      statusCode: status,
    ),
  );

  DioException connectionError() => DioException(
    requestOptions: RequestOptions(path: '/v1/scenarios'),
    type: DioExceptionType.connectionError,
  );

  // ── deleteScenario (F-11-03 idempotency) ─────────────────────────────────

  group('ScenariosRepositoryImpl.deleteScenario', () {
    void stubDelete(Object error) {
      when(() => dio.delete<void>(any())).thenThrow(error);
    }

    test('deleteScenario_status404_returnsSilently_noThrow', () async {
      // F-11-03: 404 = kaynak zaten yok = istenen son durum → sessiz başarı.
      stubDelete(dioError(404));

      await expectLater(repo.deleteScenario('abc-123'), completes);
    });

    test('deleteScenario_status500_throwsServerError', () async {
      stubDelete(dioError(500));

      expect(repo.deleteScenario('abc-123'), throwsA(isA<ServerError>()));
    });

    test('deleteScenario_connectionError_throwsNoInternet', () async {
      stubDelete(connectionError());

      expect(repo.deleteScenario('abc-123'), throwsA(isA<NoInternetError>()));
    });

    test('deleteScenario_success_completes', () async {
      when(() => dio.delete<void>(any())).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v1/scenarios/abc-123'),
          statusCode: 204,
        ),
      );

      await expectLater(repo.deleteScenario('abc-123'), completes);
    });
  });

  // ── getScenarios ──────────────────────────────────────────────────────────

  group('ScenariosRepositoryImpl.getScenarios', () {
    void stubGet(Object answer) {
      final stub = when(
        () => dio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
      if (answer is DioException) {
        stub.thenThrow(answer);
      } else {
        stub.thenAnswer((_) async => answer as Response<List<dynamic>>);
      }
    }

    Response<List<dynamic>> listResponse(List<dynamic>? data) =>
        Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/v1/scenarios'),
          statusCode: 200,
          data: data,
        );

    test('getScenarios_success_returnsList', () async {
      stubGet(listResponse([scenarioJson(), scenarioJson(id: 'def-456')]));

      final scenarios = await repo.getScenarios();

      expect(scenarios, hasLength(2));
      expect(scenarios.first.assetSymbol, 'USDTRY');
      expect(scenarios.first.amount, Decimal.fromInt(10000));
    });

    test('getScenarios_nullBody_returnsEmptyList', () async {
      stubGet(listResponse(null));

      expect(await repo.getScenarios(), isEmpty);
    });

    test('getScenarios_oneBadRow_skipsAndReports_keepsValidRows', () async {
      // F-11-20: tek bozuk satır (id int → FormatException) tüm listeyi
      // düşürmesin; hatalı atlanır, raporlanır, geçerliler döner.
      stubGet(
        listResponse([
          scenarioJson(),
          {...scenarioJson(id: 'bad'), 'id': 42}, // id int → parse hatası
        ]),
      );

      final scenarios = await repo.getScenarios();

      expect(scenarios, hasLength(1));
      // Rapor fire-and-forget (unawaited) → microtask kuyruğunu boşalt.
      await Future<void>.delayed(Duration.zero);
      expect(reporter.reports, hasLength(1));
    });

    test('getScenarios_connectionError_throwsNoInternet', () async {
      stubGet(connectionError());

      expect(repo.getScenarios(), throwsA(isA<NoInternetError>()));
    });
  });

  // ── saveScenario ──────────────────────────────────────────────────────────

  group('ScenariosRepositoryImpl.saveScenario', () {
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

    Response<Map<String, dynamic>> okResponse(Map<String, dynamic>? data) =>
        Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/scenarios'),
          statusCode: 200,
          data: data,
        );

    Future<void> save() => repo.saveScenario(
      assetSymbol: 'USDTRY',
      assetDisplayName: 'Dolar/TL',
      buyDate: DateTime(2020, 3, 1),
      sellDate: DateTime(2021, 1, 1),
      amount: 10000,
      amountType: 'try',
    );

    test('saveScenario_success_returnsScenario', () async {
      stubPost(okResponse(scenarioJson()));

      final scenario = await repo.saveScenario(
        assetSymbol: 'USDTRY',
        assetDisplayName: 'Dolar/TL',
        buyDate: DateTime(2020, 3, 1),
        amount: 10000,
        amountType: 'try',
      );

      expect(scenario.id, 'abc-123');
      expect(scenario.assetSymbol, 'USDTRY');
    });

    test('saveScenario_nullBody_throwsServerError', () async {
      stubPost(okResponse(null));

      await expectLater(
        save(),
        throwsA(
          isA<ServerError>().having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test(
      'saveScenario_status422ScenarioLimit_throwsScenarioLimitError',
      () async {
        // Mapper entegrasyonu: 422 + scenario-limit type → ScenarioLimitError.
        stubPost(
          DioException(
            requestOptions: RequestOptions(path: '/v1/scenarios'),
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/v1/scenarios'),
              statusCode: 422,
              data: {
                'type': 'https://saydin.app/errors/scenario-limit-exceeded',
                'extensions': {'limit': 5},
              },
            ),
          ),
        );

        await expectLater(
          save(),
          throwsA(isA<ScenarioLimitError>().having((e) => e.limit, 'limit', 5)),
        );
      },
    );

    test('saveScenario_connectionError_throwsNoInternet', () async {
      stubPost(connectionError());

      expect(save(), throwsA(isA<NoInternetError>()));
    });
  });
}
