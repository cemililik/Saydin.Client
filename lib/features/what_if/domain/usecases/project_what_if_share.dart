import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_share_projection.dart';

/// Maps one immutable calculation snapshot to share financial evidence.
final class WhatIfShareProjector {
  const WhatIfShareProjector();

  WhatIfShareProjection call(
    WhatIfResult result, {
    required bool inflationRequested,
  }) => WhatIfShareProjection(
    assetSymbol: result.assetSymbol,
    assetDisplayName: result.assetDisplayName,
    nominalOutcome: ShareNominalOutcome(
      initialValueTry: result.initialValueTry,
      finalValueTry: result.finalValueTry,
      profitLossTry: result.profitLossTry,
      profitLossPercent: result.profitLossPercent,
    ),
    dates: _tradeDates(
      buyDate: result.buyDate,
      actualBuyDate: result.actualBuyDate,
      sellDate: result.sellDate,
      actualSellDate: result.actualSellDate,
      fallbackSellDate: _fallbackSellDate(
        buyDate: result.buyDate,
        sellDate: result.sellDate,
        priceHistory: result.priceHistory,
        calculatedAt: result.calculatedAt,
      ),
      calculatedAt: result.calculatedAt,
    ),
    inflation: ShareInflationEvidence.fromNullable(
      requested: inflationRequested,
      cumulativeInflationPercent: result.cumulativeInflationPercent,
      realProfitLossPercent: result.realProfitLossPercent,
      cpiAsOfCandidates: [result.inflationDataAsOf],
    ),
  );
}

/// Reverse calculation counterpart of [WhatIfShareProjector].
final class ReverseWhatIfShareProjector {
  const ReverseWhatIfShareProjector();

  ReverseWhatIfShareProjection call(
    ReverseWhatIfResult result, {
    required bool inflationRequested,
  }) => ReverseWhatIfShareProjection(
    assetSymbol: result.assetSymbol,
    assetDisplayName: result.assetDisplayName,
    nominalOutcome: ShareNominalOutcome(
      initialValueTry: result.requiredInvestmentTry,
      finalValueTry: result.targetValueTry,
      profitLossTry: result.profitLossTry,
      profitLossPercent: result.profitLossPercent,
    ),
    dates: _tradeDates(
      buyDate: result.buyDate,
      actualBuyDate: result.actualBuyDate,
      sellDate: result.sellDate,
      actualSellDate: result.actualSellDate,
      fallbackSellDate: _fallbackSellDate(
        buyDate: result.buyDate,
        sellDate: result.sellDate,
        priceHistory: result.priceHistory,
        calculatedAt: result.calculatedAt,
      ),
      calculatedAt: result.calculatedAt,
    ),
    inflation: ShareInflationEvidence.fromNullable(
      requested: inflationRequested,
      cumulativeInflationPercent: result.cumulativeInflationPercent,
      realProfitLossPercent: result.realProfitLossPercent,
      cpiAsOfCandidates: [result.inflationDataAsOf],
    ),
  );
}

ShareDateEvidence _tradeDates({
  required DateTime buyDate,
  required DateTime? actualBuyDate,
  required DateTime? sellDate,
  required DateTime? actualSellDate,
  required DateTime fallbackSellDate,
  required DateTime? calculatedAt,
}) => ShareDateEvidence(
  context: ShareDateContext.trade,
  requestedBuy: ShareDateValue.single(buyDate),
  effectiveBuy: ShareDateValue.single(actualBuyDate ?? buyDate),
  requestedSell: ShareDateValue.fromCandidates([sellDate]),
  effectiveSell: ShareDateValue.single(actualSellDate ?? fallbackSellDate),
  calculatedAt: ShareDateValue.fromCandidates([calculatedAt]),
);

DateTime _fallbackSellDate({
  required DateTime buyDate,
  required DateTime? sellDate,
  required List<ChartPoint> priceHistory,
  required DateTime? calculatedAt,
}) {
  if (sellDate != null) return sellDate;
  if (priceHistory.isNotEmpty) {
    return priceHistory
        .map((point) => point.date)
        .reduce((left, right) => right.isAfter(left) ? right : left);
  }
  if (calculatedAt != null) {
    return DateTime(calculatedAt.year, calculatedAt.month, calculatedAt.day);
  }
  return buyDate;
}
