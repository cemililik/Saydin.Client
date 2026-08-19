import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/domain/usecases/project_portfolio_share.dart';

void main() {
  PortfolioItem item(String symbol) => PortfolioItem(
    id: symbol,
    assetSymbol: symbol,
    assetDisplayName: symbol,
    amount: Decimal.fromInt(100),
    amountType: 'try',
  );

  PortfolioCalculation calculation({
    required DateTime effectiveBuy,
    required DateTime effectiveSell,
    DateTime? cpiAsOf,
  }) => PortfolioCalculation(
    initialValueTry: Decimal.fromInt(100),
    finalValueTry: Decimal.fromInt(120),
    profitLossPercent: 20,
    isProfit: true,
    realProfitLossPercent: 10,
    requestedBuyDate: DateTime(2024, 1, 1),
    effectiveBuyDate: effectiveBuy,
    requestedSellDate: DateTime(2024, 2, 1),
    effectiveSellDate: effectiveSell,
    inflationDataAsOf: cpiAsOf,
  );

  test('portfolio exposes mixed ranges and independent aggregate metrics', () {
    final first = item('AAA');
    final second = item('BBB');
    final failed = item('CCC');
    final result = PortfolioResult(
      items: [
        PortfolioItemResult(
          item: first,
          calculation: calculation(
            effectiveBuy: DateTime(2024, 1, 2),
            effectiveSell: DateTime(2024, 2, 2),
            cpiAsOf: DateTime(2024, 1, 31),
          ),
          sharePercent: 50,
        ),
        PortfolioItemResult(
          item: second,
          calculation: calculation(
            effectiveBuy: DateTime(2024, 1, 3),
            effectiveSell: DateTime(2024, 2, 5),
          ),
          sharePercent: 50,
        ),
      ],
      failures: [
        PortfolioItemFailure(item: failed, error: const ServerError()),
      ],
      totalInitialValueTry: Decimal.fromInt(200),
      totalFinalValueTry: Decimal.fromInt(240),
      totalProfitLossTry: Decimal.fromInt(40),
      totalProfitLossPercent: 20,
      isProfit: true,
      requestedBuyDate: DateTime(2024, 1, 1),
      requestedSellDate: DateTime(2024, 2, 1),
      effectiveSellDate: DateTime(2024, 2, 1),
      calculatedAt: DateTime(2024, 2, 6, 10),
      totalRealProfitLossTry: Decimal.fromInt(20),
      totalRealProfitLossPercent: 10,
      totalCumulativeInflationPercent: null,
    );

    final projection = const PortfolioShareProjector()(
      result,
      inflationRequested: true,
    );

    expect(projection.isPartial, isTrue);
    expect(projection.failureCount, 1);
    expect(projection.dates.effectiveBuy.coverage, ShareDateCoverage.partial);
    expect(projection.dates.effectiveBuy.isRange, isTrue);
    expect(projection.dates.effectiveSell.coverage, ShareDateCoverage.partial);
    expect(projection.inflation.cpiAsOf.coverage, ShareDateCoverage.partial);
    expect(projection.inflation.realProfitLossTry.value, Decimal.fromInt(20));
    expect(projection.inflation.realProfitLossPercent.value, 10);
    expect(
      projection.inflation.cumulativeInflationPercent.availability,
      ShareMetricAvailability.unavailable,
    );
    expect(projection.inflation.cumulativeInflationPercent.value, isNull);
  });
}
