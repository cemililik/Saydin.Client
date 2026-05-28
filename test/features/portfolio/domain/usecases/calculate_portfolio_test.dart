import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

class MockWhatIfRepository extends Mock implements WhatIfRepository {}

void main() {
  late MockWhatIfRepository repo;
  late CalculatePortfolio usecase;

  setUpAll(() => registerFallbackValue(DateTime(2020)));

  setUp(() {
    repo = MockWhatIfRepository();
    usecase = CalculatePortfolio(repo);
  });

  // ── Test yardımcıları ────────────────────────────────────────────────────
  PortfolioItem item(String symbol) => PortfolioItem(
    id: symbol,
    assetSymbol: symbol,
    assetDisplayName: symbol,
    amount: 1000,
    amountType: 'try',
  );

  WhatIfResult whatIf(
    String symbol, {
    required String initial,
    required String finalV,
    double? realPct,
    double? cumInfl,
  }) {
    final init = Decimal.parse(initial);
    final fin = Decimal.parse(finalV);
    return WhatIfResult(
      assetSymbol: symbol,
      assetDisplayName: symbol,
      buyDate: DateTime(2020, 1, 1),
      sellDate: DateTime(2021, 1, 1),
      buyPrice: Decimal.one,
      sellPrice: Decimal.one,
      unitsAcquired: Decimal.one,
      initialValueTry: init,
      finalValueTry: fin,
      profitLossTry: fin - init,
      profitLossPercent: 0,
      isProfit: fin >= init,
      realProfitLossPercent: realPct,
      cumulativeInflationPercent: cumInfl,
    );
  }

  void stubResult(String symbol, WhatIfResult result) {
    when(
      () => repo.calculate(
        assetSymbol: symbol,
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        amount: any(named: 'amount'),
        amountType: any(named: 'amountType'),
        includeInflation: any(named: 'includeInflation'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubThrow(String symbol) {
    when(
      () => repo.calculate(
        assetSymbol: symbol,
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        amount: any(named: 'amount'),
        amountType: any(named: 'amountType'),
        includeInflation: any(named: 'includeInflation'),
      ),
    ).thenThrow(Exception('backend 503'));
  }

  Future<dynamic> run(List<PortfolioItem> items, {bool inflation = false}) =>
      usecase.call(
        items: items,
        buyDate: DateTime(2020, 1, 1),
        sellDate: DateTime(2021, 1, 1),
        includeInflation: inflation,
      );

  group('CalculatePortfolio — Decimal aggregasyon (happy path)', () {
    test('initial/final toplamları exact Decimal — 0.1 + 0.2 == 0.3', () async {
      stubResult('AAA', whatIf('AAA', initial: '0.1', finalV: '0.15'));
      stubResult('BBB', whatIf('BBB', initial: '0.2', finalV: '0.25'));

      final result = await run([item('AAA'), item('BBB')]);

      // IEEE-754 double olsaydı 0.30000000000000004 olurdu — Decimal exact.
      expect(result.totalInitialValueTry, Decimal.parse('0.3'));
      expect(result.totalFinalValueTry, Decimal.parse('0.4'));
      expect(result.totalProfitLossTry, Decimal.parse('0.1'));
      expect(result.isProfit, isTrue);
      expect(result.failedItems, isEmpty);
      expect(result.hasPartialFailure, isFalse);
      expect(result.items, hasLength(2));
    });

    test('zarar durumunda isProfit false', () async {
      stubResult('AAA', whatIf('AAA', initial: '1000', finalV: '900'));

      final result = await run([item('AAA')]);

      expect(result.totalProfitLossTry, Decimal.parse('-100'));
      expect(result.isProfit, isFalse);
    });
  });

  group('CalculatePortfolio — partial failure', () {
    test('bir kalem çökerse partial success + failedItems', () async {
      stubResult('AAA', whatIf('AAA', initial: '1000', finalV: '1200'));
      stubThrow('BBB');

      final result = await run([item('AAA'), item('BBB')]);

      expect(result.items, hasLength(1));
      expect(result.failedItems, hasLength(1));
      expect(result.failedItems.single.assetSymbol, 'BBB');
      expect(result.hasPartialFailure, isTrue);
      // Toplam yalnızca başarılı kalemden hesaplanır.
      expect(result.totalInitialValueTry, Decimal.parse('1000'));
      expect(result.totalFinalValueTry, Decimal.parse('1200'));
    });

    test('tüm kalemler çökerse PortfolioCalculationFailure', () async {
      stubThrow('AAA');
      stubThrow('BBB');

      expect(
        () => run([item('AAA'), item('BBB')]),
        throwsA(isA<PortfolioCalculationFailure>()),
      );
    });
  });

  group('CalculatePortfolio — enflasyon aggregasyonu', () {
    test('includeInflation: reel P/L exact Decimal aritmetiği', () async {
      // initial 100, realPct 10 → realFactor (100+10)/100 = 1.10
      // realFinal = 110 → realPnL = 10
      stubResult(
        'AAA',
        whatIf('AAA', initial: '100', finalV: '130', realPct: 10, cumInfl: 5),
      );

      final result = await run([item('AAA')], inflation: true);

      expect(result.totalRealProfitLossTry, Decimal.parse('10'));
      expect(result.hasInflation, isTrue);
      expect(result.totalCumulativeInflationPercent, 5);
    });

    test(
      'PR1 precision fix: realPct 33.3333 → reel P/L double sızıntısı olmadan exact',
      () async {
        // (100 + 33.3333) / 100 = 1.333333 (Decimal, /100 her zaman finite)
        // realFinal = 300 * 1.333333 = 399.9999 → realPnL = 99.9999
        // Eski double yaklaşımı IEEE-754 gürültüsü sızdırabilirdi.
        stubResult(
          'AAA',
          whatIf('AAA', initial: '300', finalV: '300', realPct: 33.3333),
        );

        final result = await run([item('AAA')], inflation: true);

        expect(result.totalRealProfitLossTry, Decimal.parse('99.9999'));
      },
    );

    test(
      'realProfitLossPercent kısmen null → reel alanlar hesaplanmaz',
      () async {
        stubResult(
          'AAA',
          whatIf('AAA', initial: '100', finalV: '110', realPct: 10),
        );
        // BBB'de realPct null → every() false → reel aggregasyon atlanır.
        stubResult('BBB', whatIf('BBB', initial: '100', finalV: '120'));

        final result = await run([item('AAA'), item('BBB')], inflation: true);

        expect(result.totalRealProfitLossTry, isNull);
        expect(result.totalRealProfitLossPercent, isNull);
        expect(result.totalCumulativeInflationPercent, isNull);
        expect(result.hasInflation, isFalse);
      },
    );

    test(
      'cumulativeInflationPercent kısmen null → reel P/L dolu, toplam enflasyon null',
      () async {
        // Her ikisinde realPct var (reel P/L hesaplanır) ama BBB'de cumInfl null
        // → ağırlıklı enflasyon atlanır.
        stubResult(
          'AAA',
          whatIf('AAA', initial: '100', finalV: '110', realPct: 10, cumInfl: 5),
        );
        stubResult(
          'BBB',
          whatIf('BBB', initial: '100', finalV: '120', realPct: 20),
        );

        final result = await run([item('AAA'), item('BBB')], inflation: true);

        expect(result.totalRealProfitLossTry, isNotNull);
        expect(result.totalCumulativeInflationPercent, isNull);
      },
    );
  });
}
