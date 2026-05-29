import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

class MockWhatIfRepository extends Mock implements WhatIfRepository {}

/// L-2: per-item catch'te beklenmedik (non-AppError) hataların fire-and-forget
/// raporlandığını saymak için fake reporter.
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

void main() {
  late MockWhatIfRepository whatIf;
  late _FakeErrorReporter reporter;
  late PortfolioRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(DateTime(2020)));

  setUp(() {
    whatIf = MockWhatIfRepository();
    reporter = _FakeErrorReporter();
    repo = PortfolioRepositoryImpl(whatIf, reporter: reporter);
  });

  PortfolioItem item(String symbol) => PortfolioItem(
    id: symbol,
    assetSymbol: symbol,
    assetDisplayName: symbol,
    amount: 1000,
    amountType: 'try',
  );

  WhatIfResult whatIfResult(String symbol) => WhatIfResult(
    assetSymbol: symbol,
    assetDisplayName: symbol,
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    buyPrice: Decimal.one,
    sellPrice: Decimal.one,
    unitsAcquired: Decimal.one,
    initialValueTry: Decimal.fromInt(1000),
    finalValueTry: Decimal.fromInt(1200),
    profitLossTry: Decimal.fromInt(200),
    profitLossPercent: 20,
    isProfit: true,
    cumulativeInflationPercent: 5,
    realProfitLossPercent: 14,
  );

  void stubCalc(String symbol, {Object? throws, WhatIfResult? result}) {
    final stub = when(
      () => whatIf.calculate(
        assetSymbol: symbol,
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        amount: any(named: 'amount'),
        amountType: any(named: 'amountType'),
        includeInflation: any(named: 'includeInflation'),
      ),
    );
    if (throws != null) {
      stub.thenThrow(throws);
    } else {
      stub.thenAnswer((_) async => result!);
    }
  }

  test(
    'calculateItems_perItem_mapsWhatIfResultToPortfolioCalculation',
    () async {
      stubCalc('AAA', result: whatIfResult('AAA'));

      final outcomes = await repo.calculateItems(
        items: [item('AAA')],
        buyDate: DateTime(2020, 1, 1),
        sellDate: DateTime(2021, 1, 1),
      );

      expect(outcomes, hasLength(1));
      final calc = outcomes.single.calculation;
      expect(calc, isNotNull);
      expect(calc!.initialValueTry, Decimal.fromInt(1000));
      expect(calc.finalValueTry, Decimal.fromInt(1200));
      expect(calc.profitLossPercent, 20);
      expect(calc.isProfit, isTrue);
      expect(calc.cumulativeInflationPercent, 5);
      expect(calc.realProfitLossPercent, 14);
    },
  );

  test(
    'calculateItems_perItemIsolation_appError_itemCalculationNull_othersSuccess',
    () async {
      stubCalc('AAA', result: whatIfResult('AAA'));
      // BBB backend hatası (repo bunu AppError olarak fırlatır) → izole edilir.
      stubCalc('BBB', throws: const ServerError());

      final outcomes = await repo.calculateItems(
        items: [item('AAA'), item('BBB')],
        buyDate: DateTime(2020, 1, 1),
        sellDate: DateTime(2021, 1, 1),
      );

      expect(outcomes, hasLength(2));
      final aaa = outcomes.firstWhere((o) => o.item.assetSymbol == 'AAA');
      final bbb = outcomes.firstWhere((o) => o.item.assetSymbol == 'BBB');
      expect(aaa.isSuccess, isTrue);
      expect(bbb.isSuccess, isFalse);
      expect(bbb.calculation, isNull);
    },
  );

  test('calculateItems_appError_notReported', () async {
    stubCalc('AAA', throws: const ServerError());

    final outcomes = await repo.calculateItems(
      items: [item('AAA')],
      buyDate: DateTime(2020, 1, 1),
      sellDate: DateTime(2021, 1, 1),
    );

    expect(outcomes.single.calculation, isNull);
    // Rapor fire-and-forget olsaydı bile microtask'i boşaltalım — yine de boş.
    await Future<void>.delayed(Duration.zero);
    expect(
      reporter.reports,
      isEmpty,
      reason: 'AppError beklenen hata; telemetri gürültüsü üretmemeli',
    );
  });

  test('calculateItems_nonAppError_fireAndForget_isReported', () async {
    // Beklenmedik programlama hatası (örn. TypeError) "veri yok" gibi
    // sessizce maskelenmemeli; izolasyon korunur ama telemetri gider.
    stubCalc('AAA', throws: ArgumentError('beklenmedik'));

    final outcomes = await repo.calculateItems(
      items: [item('AAA')],
      buyDate: DateTime(2020, 1, 1),
      sellDate: DateTime(2021, 1, 1),
    );

    expect(outcomes.single.calculation, isNull, reason: 'izolasyon korunur');
    await Future<void>.delayed(Duration.zero);
    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single, isA<ArgumentError>());
  });
}
