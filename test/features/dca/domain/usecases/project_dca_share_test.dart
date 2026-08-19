import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/usecases/project_dca_share.dart';

void main() {
  test('DCA keeps purchase range, calculation time and partial inflation', () {
    final result = DcaResult(
      assetSymbol: 'BTC',
      assetDisplayName: 'Bitcoin',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 3, 31),
      period: 'monthly',
      periodicAmount: Decimal.fromInt(1000),
      totalPurchases: 2,
      totalInvestedTry: Decimal.fromInt(2000),
      currentValueTry: Decimal.fromInt(2300),
      profitLossTry: Decimal.fromInt(300),
      profitLossPercent: 15,
      isProfit: true,
      averageCostPerUnit: Decimal.fromInt(10),
      totalUnitsAcquired: Decimal.fromInt(200),
      currentUnitPrice: Decimal.parse('11.5'),
      realProfitLossPercent: 8,
      calculatedAt: DateTime(2024, 4, 1, 9),
      purchases: [
        DcaPurchase(
          date: DateTime(2024, 1, 2),
          price: Decimal.fromInt(10),
          unitsAcquired: Decimal.fromInt(100),
          cumulativeUnits: Decimal.fromInt(100),
          cumulativeCostTry: Decimal.fromInt(1000),
          cumulativeValueTry: Decimal.fromInt(1000),
        ),
        DcaPurchase(
          date: DateTime(2024, 3, 4),
          price: Decimal.fromInt(10),
          unitsAcquired: Decimal.fromInt(100),
          cumulativeUnits: Decimal.fromInt(200),
          cumulativeCostTry: Decimal.fromInt(2000),
          cumulativeValueTry: Decimal.fromInt(2300),
        ),
      ],
    );

    final projection = const DcaShareProjector()(
      result,
      inflationRequested: true,
    );

    expect(projection.dates.context, ShareDateContext.recurringInvestment);
    expect(projection.dates.effectiveBuy.earliest, DateTime(2024, 1, 2));
    expect(projection.dates.effectiveBuy.latest, DateTime(2024, 3, 4));
    expect(projection.dates.calculatedAt.earliest, DateTime(2024, 4, 1, 9));
    expect(
      projection.inflation.cumulativeInflationPercent.availability,
      ShareMetricAvailability.unavailable,
    );
    expect(projection.inflation.realProfitLossPercent.value, 8);
  });
}
