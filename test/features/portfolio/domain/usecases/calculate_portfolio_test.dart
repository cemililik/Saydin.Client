import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';

class MockPortfolioRepository extends Mock implements PortfolioRepository {}

void main() {
  late MockPortfolioRepository repo;
  late CalculatePortfolio usecase;

  setUpAll(() {
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(<PortfolioItem>[]);
  });

  setUp(() {
    repo = MockPortfolioRepository();
    usecase = CalculatePortfolio(repo);
  });

  // ── Test yardımcıları ────────────────────────────────────────────────────
  PortfolioItem item(String symbol) => PortfolioItem(
    id: symbol,
    assetSymbol: symbol,
    assetDisplayName: symbol,
    amount: Decimal.fromInt(1000),
    amountType: 'try',
  );

  PortfolioCalculation calc({
    required String initial,
    required String finalV,
    double? realPct,
    double? cumInfl,
  }) {
    final init = Decimal.parse(initial);
    final fin = Decimal.parse(finalV);
    return PortfolioCalculation(
      initialValueTry: init,
      finalValueTry: fin,
      profitLossPercent: 0,
      isProfit: fin >= init,
      realProfitLossPercent: realPct,
      cumulativeInflationPercent: cumInfl,
    );
  }

  /// Repository'nin döndüreceği per-item outcome listesini stub'lar. `calc`
  /// `null` ise o kalem hesaplanamamış (failed) sayılır — repository per-item
  /// izolasyon sözleşmesi.
  void stubOutcomes(List<PortfolioItemOutcome> outcomes) {
    when(
      () => repo.calculateItems(
        items: any(named: 'items'),
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        includeInflation: any(named: 'includeInflation'),
      ),
    ).thenAnswer((_) async => outcomes);
  }

  Future<dynamic> run(List<PortfolioItem> items, {bool inflation = false}) =>
      usecase.call(
        items: items,
        buyDate: DateTime(2020, 1, 1),
        sellDate: DateTime(2021, 1, 1),
        includeInflation: inflation,
      );

  group('CalculatePortfolio — Decimal aggregasyon (happy path)', () {
    test(
      'açık uçlu sonuç effectiveSellDate değerini fake clock ile sabitler',
      () async {
        final a = item('AAA');
        stubOutcomes([
          PortfolioItemCalculatedOutcome(
            item: a,
            calculation: calc(initial: '100', finalV: '120'),
          ),
        ]);
        usecase = CalculatePortfolio(
          repo,
          clock: () => DateTime(2024, 7, 9, 23, 59),
        );

        final result = await usecase.call(
          items: [a],
          buyDate: DateTime(2020, 1, 1),
        );

        expect(result.effectiveSellDate, DateTime(2024, 7, 9));
      },
    );

    test('initial/final toplamları exact Decimal — 0.1 + 0.2 == 0.3', () async {
      final a = item('AAA');
      final b = item('BBB');
      stubOutcomes([
        PortfolioItemCalculatedOutcome(
          item: a,
          calculation: calc(initial: '0.1', finalV: '0.15'),
        ),
        PortfolioItemCalculatedOutcome(
          item: b,
          calculation: calc(initial: '0.2', finalV: '0.25'),
        ),
      ]);

      final result = await run([a, b]);

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
      final a = item('AAA');
      stubOutcomes([
        PortfolioItemCalculatedOutcome(
          item: a,
          calculation: calc(initial: '1000', finalV: '900'),
        ),
      ]);

      final result = await run([a]);

      expect(result.totalProfitLossTry, Decimal.parse('-100'));
      expect(result.isProfit, isFalse);
    });
  });

  group('CalculatePortfolio — partial failure', () {
    test('bir kalem çökerse partial success + failedItems', () async {
      final a = item('AAA');
      final b = item('BBB');
      stubOutcomes([
        PortfolioItemCalculatedOutcome(
          item: a,
          calculation: calc(initial: '1000', finalV: '1200'),
        ),
        // BBB hesaplanamadı (repo izolasyonu → calculation: null).
        PortfolioItemErrorOutcome(item: b, error: const ServerError()),
      ]);

      final result = await run([a, b]);

      expect(result.items, hasLength(1));
      expect(result.failedItems, hasLength(1));
      expect(result.failedItems.single.assetSymbol, 'BBB');
      expect(result.hasPartialFailure, isTrue);
      // Toplam yalnızca başarılı kalemden hesaplanır.
      expect(result.totalInitialValueTry, Decimal.parse('1000'));
      expect(result.totalFinalValueTry, Decimal.parse('1200'));
    });

    test('tüm kalemler çökerse PortfolioCalculationFailure', () async {
      final a = item('AAA');
      final b = item('BBB');
      stubOutcomes([
        PortfolioItemErrorOutcome(item: a, error: const ServerError()),
        PortfolioItemErrorOutcome(item: b, error: const NoInternetError()),
      ]);

      expect(() => run([a, b]), throwsA(isA<NoInternetError>()));
    });
  });

  group('CalculatePortfolio — enflasyon aggregasyonu', () {
    test('includeInflation: reel P/L exact Decimal aritmetiği', () async {
      // initial 100, realPct 10 → realFactor (100+10)/100 = 1.10
      // realFinal = 110 → realPnL = 10
      final a = item('AAA');
      stubOutcomes([
        PortfolioItemCalculatedOutcome(
          item: a,
          calculation: calc(
            initial: '100',
            finalV: '130',
            realPct: 10,
            cumInfl: 5,
          ),
        ),
      ]);

      final result = await run([a], inflation: true);

      expect(result.totalRealProfitLossTry, Decimal.parse('10'));
      expect(result.hasInflation, isTrue);
      expect(result.totalCumulativeInflationPercent, 5);
    });

    test(
      'PR1 precision fix: realPct 33.3333 → reel P/L double sızıntısı olmadan exact',
      () async {
        // (100 + 33.3333) / 100 = 1.333333 (Decimal, /100 her zaman finite)
        // realFinal = 300 * 1.333333 = 399.9999 → realPnL = 99.9999
        final a = item('AAA');
        stubOutcomes([
          PortfolioItemCalculatedOutcome(
            item: a,
            calculation: calc(initial: '300', finalV: '300', realPct: 33.3333),
          ),
        ]);

        final result = await run([a], inflation: true);

        expect(result.totalRealProfitLossTry, Decimal.parse('99.9999'));
      },
    );

    test(
      'realProfitLossPercent kısmen null → reel alanlar hesaplanmaz',
      () async {
        final a = item('AAA');
        final b = item('BBB');
        stubOutcomes([
          PortfolioItemCalculatedOutcome(
            item: a,
            calculation: calc(initial: '100', finalV: '110', realPct: 10),
          ),
          // BBB'de realPct null → every() false → reel aggregasyon atlanır.
          PortfolioItemCalculatedOutcome(
            item: b,
            calculation: calc(initial: '100', finalV: '120'),
          ),
        ]);

        final result = await run([a, b], inflation: true);

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
        final a = item('AAA');
        final b = item('BBB');
        stubOutcomes([
          PortfolioItemCalculatedOutcome(
            item: a,
            calculation: calc(
              initial: '100',
              finalV: '110',
              realPct: 10,
              cumInfl: 5,
            ),
          ),
          PortfolioItemCalculatedOutcome(
            item: b,
            calculation: calc(initial: '100', finalV: '120', realPct: 20),
          ),
        ]);

        final result = await run([a, b], inflation: true);

        expect(result.totalRealProfitLossTry, isNotNull);
        expect(result.totalCumulativeInflationPercent, isNull);
      },
    );
  });
}
