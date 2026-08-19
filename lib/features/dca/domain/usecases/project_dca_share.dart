import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/entities/dca_share_projection.dart';

/// Projects DCA evidence without deriving missing inflation values.
final class DcaShareProjector {
  const DcaShareProjector();

  DcaShareProjection call(
    DcaResult result, {
    required bool inflationRequested,
  }) {
    final effectivePurchaseDates = result.purchases.isEmpty
        ? <DateTime?>[result.startDate, result.endDate]
        : result.purchases.map<DateTime?>((purchase) => purchase.date).toList();

    return DcaShareProjection(
      assetSymbol: result.assetSymbol,
      assetDisplayName: result.assetDisplayName,
      period: result.period,
      periodicAmount: result.periodicAmount,
      totalPurchases: result.totalPurchases,
      nominalOutcome: ShareNominalOutcome(
        initialValueTry: result.totalInvestedTry,
        finalValueTry: result.currentValueTry,
        profitLossTry: result.profitLossTry,
        profitLossPercent: result.profitLossPercent,
      ),
      dates: ShareDateEvidence(
        context: ShareDateContext.recurringInvestment,
        requestedBuy: ShareDateValue.range(result.startDate, result.endDate),
        effectiveBuy: ShareDateValue.fromCandidates(effectivePurchaseDates),
        requestedSell: ShareDateValue.single(result.endDate),
        effectiveSell: ShareDateValue.single(result.endDate),
        calculatedAt: ShareDateValue.fromCandidates([result.calculatedAt]),
      ),
      inflation: ShareInflationEvidence.fromNullable(
        requested: inflationRequested,
        cumulativeInflationPercent: result.cumulativeInflationPercent,
        realProfitLossPercent: result.realProfitLossPercent,
        cpiAsOfCandidates: [result.inflationDataAsOf],
      ),
    );
  }
}
