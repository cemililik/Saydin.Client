import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/usecases/project_what_if_share.dart';

void main() {
  test('what-if preserves requested/actual dates and partial inflation', () {
    final result = WhatIfResult(
      assetSymbol: 'XAU',
      assetDisplayName: 'Altın',
      buyDate: DateTime(2024, 6, 8),
      sellDate: DateTime(2024, 6, 16),
      actualBuyDate: DateTime(2024, 6, 10),
      actualSellDate: DateTime(2024, 6, 17),
      calculatedAt: DateTime(2024, 6, 17, 12, 30),
      buyPrice: Decimal.parse('2400.10'),
      sellPrice: Decimal.parse('2500.20'),
      unitsAcquired: Decimal.one,
      initialValueTry: Decimal.parse('2400.10'),
      finalValueTry: Decimal.parse('2500.20'),
      profitLossTry: Decimal.parse('100.10'),
      profitLossPercent: 4.1706,
      isProfit: true,
      cumulativeInflationPercent: null,
      realProfitLossPercent: 1.25,
      inflationDataAsOf: DateTime(2024, 5, 31),
    );

    final projection = const WhatIfShareProjector()(
      result,
      inflationRequested: true,
    );

    expect(projection.dates.requestedBuy.earliest, DateTime(2024, 6, 8));
    expect(projection.dates.effectiveBuy.earliest, DateTime(2024, 6, 10));
    expect(projection.dates.requestedSell.earliest, DateTime(2024, 6, 16));
    expect(projection.dates.effectiveSell.earliest, DateTime(2024, 6, 17));
    expect(
      projection.inflation.cumulativeInflationPercent.availability,
      ShareMetricAvailability.unavailable,
    );
    expect(projection.inflation.cumulativeInflationPercent.value, isNull);
    expect(projection.inflation.realProfitLossPercent.value, 1.25);
    expect(projection.inflation.cpiAsOf.earliest, DateTime(2024, 5, 31));
    expect(projection.nominalOutcome.profitLossTry, Decimal.parse('100.10'));
  });

  test('reverse projection uses required investment and target as outcome', () {
    final result = ReverseWhatIfResult(
      assetSymbol: 'USD',
      assetDisplayName: 'Dolar',
      buyDate: DateTime(2020),
      buyPrice: Decimal.one,
      sellPrice: Decimal.fromInt(2),
      requiredInvestmentTry: Decimal.fromInt(500),
      unitsAcquired: Decimal.fromInt(500),
      targetValueTry: Decimal.fromInt(1000),
      profitLossTry: Decimal.fromInt(500),
      profitLossPercent: 100,
      isProfit: true,
    );

    final projection = const ReverseWhatIfShareProjector()(
      result,
      inflationRequested: false,
    );

    expect(projection.nominalOutcome.initialValueTry, Decimal.fromInt(500));
    expect(projection.nominalOutcome.finalValueTry, Decimal.fromInt(1000));
    expect(
      projection.inflation.realProfitLossPercent.availability,
      ShareMetricAvailability.notRequested,
    );
  });
}
