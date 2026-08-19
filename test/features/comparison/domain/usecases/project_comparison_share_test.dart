import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/entities/comparison_share_projection.dart';
import 'package:saydin/features/comparison/domain/usecases/project_comparison_share.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

void main() {
  WhatIfResult calculation(
    String symbol, {
    required DateTime actualBuyDate,
    required DateTime actualSellDate,
    double? realReturn,
    DateTime? cpiAsOf,
  }) => WhatIfResult(
    assetSymbol: symbol,
    assetDisplayName: symbol,
    buyDate: DateTime(2024, 1, 1),
    sellDate: DateTime(2024, 2, 1),
    actualBuyDate: actualBuyDate,
    actualSellDate: actualSellDate,
    calculatedAt: DateTime(2024, 2, 2, 10),
    buyPrice: Decimal.one,
    sellPrice: Decimal.fromInt(2),
    unitsAcquired: Decimal.one,
    initialValueTry: Decimal.fromInt(100),
    finalValueTry: Decimal.fromInt(120),
    profitLossTry: Decimal.fromInt(20),
    profitLossPercent: 20,
    isProfit: true,
    realProfitLossPercent: realReturn,
    inflationDataAsOf: cpiAsOf,
  );

  test('real mode never falls back to nominal and dates remain mixed', () {
    final result = CompareResult(
      results: [
        CompareResultItem(
          rank: 1,
          calculation: calculation(
            'AAA',
            actualBuyDate: DateTime(2024, 1, 2),
            actualSellDate: DateTime(2024, 2, 2),
            realReturn: 5,
            cpiAsOf: DateTime(2024, 1, 31),
          ),
        ),
        CompareResultItem(
          rank: 2,
          calculation: calculation(
            'BBB',
            actualBuyDate: DateTime(2024, 1, 3),
            actualSellDate: DateTime(2024, 2, 5),
          ),
        ),
      ],
    );

    final projection = const ComparisonShareProjector()(
      result,
      inflationRequested: true,
      returnMode: ComparisonShareReturnMode.real,
    );

    expect(projection.returnMode, ComparisonShareReturnMode.real);
    expect(
      projection.rankingBasis,
      ComparisonShareRankingBasis.realProfitLossPercentAvailableSubset,
    );
    expect(projection.items.first.sourceRank, 1);
    expect(projection.items.first.displayRank, 1);
    expect(projection.items.last.sourceRank, 2);
    expect(projection.items.last.displayRank, isNull);
    expect(projection.items.first.returnFor(projection.returnMode).value, 5);
    expect(
      projection.items.last.returnFor(projection.returnMode).availability,
      ShareMetricAvailability.unavailable,
    );
    expect(
      projection.items.last.returnFor(projection.returnMode).value,
      isNull,
    );
    expect(projection.dates.effectiveBuy.isRange, isTrue);
    expect(projection.dates.effectiveSell.isRange, isTrue);
    expect(projection.cpiAsOf.coverage, ShareDateCoverage.partial);
  });

  test(
    'real ranking reorders available values and leaves missing unranked',
    () {
      final result = CompareResult(
        results: [
          CompareResultItem(
            rank: 1,
            calculation: calculation(
              'NOMINAL_WINNER',
              actualBuyDate: DateTime(2024, 1, 2),
              actualSellDate: DateTime(2024, 2, 2),
              realReturn: -2,
            ),
          ),
          CompareResultItem(
            rank: 2,
            calculation: calculation(
              'REAL_WINNER',
              actualBuyDate: DateTime(2024, 1, 2),
              actualSellDate: DateTime(2024, 2, 2),
              realReturn: 8,
            ),
          ),
          CompareResultItem(
            rank: 3,
            calculation: calculation(
              'NO_REAL',
              actualBuyDate: DateTime(2024, 1, 2),
              actualSellDate: DateTime(2024, 2, 2),
            ),
          ),
        ],
      );

      final projection = const ComparisonShareProjector()(
        result,
        inflationRequested: true,
        returnMode: ComparisonShareReturnMode.real,
      );

      expect(projection.items.map((item) => item.assetSymbol), [
        'REAL_WINNER',
        'NOMINAL_WINNER',
        'NO_REAL',
      ]);
      expect(projection.items.map((item) => item.displayRank), [1, 2, null]);
      expect(projection.items.last.sourceRank, 3);
    },
  );

  test('real mode with no real evidence exposes unavailable ranking', () {
    final result = CompareResult(
      results: [
        CompareResultItem(
          rank: 1,
          calculation: calculation(
            'AAA',
            actualBuyDate: DateTime(2024, 1, 2),
            actualSellDate: DateTime(2024, 2, 2),
          ),
        ),
      ],
    );

    final projection = const ComparisonShareProjector()(
      result,
      inflationRequested: true,
      returnMode: ComparisonShareReturnMode.real,
    );

    expect(projection.rankingBasis, ComparisonShareRankingBasis.unavailable);
    expect(projection.items.single.displayRank, isNull);
    expect(projection.items.single.sourceRank, 1);
  });

  test('nominal mode computes evidence-based rank, preserving source rank', () {
    final lower = calculation(
      'LOWER',
      actualBuyDate: DateTime(2024, 1, 2),
      actualSellDate: DateTime(2024, 2, 2),
    );
    final higher = WhatIfResult(
      assetSymbol: 'HIGHER',
      assetDisplayName: 'HIGHER',
      buyDate: DateTime(2024, 1, 1),
      sellDate: DateTime(2024, 2, 1),
      buyPrice: Decimal.one,
      sellPrice: Decimal.fromInt(3),
      unitsAcquired: Decimal.one,
      initialValueTry: Decimal.fromInt(100),
      finalValueTry: Decimal.fromInt(130),
      profitLossTry: Decimal.fromInt(30),
      profitLossPercent: 30,
      isProfit: true,
    );
    final projection = const ComparisonShareProjector()(
      CompareResult(
        results: [
          CompareResultItem(rank: 1, calculation: lower),
          CompareResultItem(rank: 2, calculation: higher),
        ],
      ),
      inflationRequested: false,
      returnMode: ComparisonShareReturnMode.nominal,
    );

    expect(
      projection.rankingBasis,
      ComparisonShareRankingBasis.nominalProfitLossPercent,
    );
    expect(projection.items.first.assetSymbol, 'HIGHER');
    expect(projection.items.first.displayRank, 1);
    expect(projection.items.first.sourceRank, 2);
  });
}
