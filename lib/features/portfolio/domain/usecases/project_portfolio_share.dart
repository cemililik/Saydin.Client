import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_share_projection.dart';

/// Projects aggregate and per-item evidence without selecting an optimistic
/// single date from mixed portfolio snapshots.
final class PortfolioShareProjector {
  const PortfolioShareProjector();

  PortfolioShareProjection call(
    PortfolioResult result, {
    required bool inflationRequested,
  }) {
    final failurePlaceholders = List<DateTime?>.filled(
      result.failures.length,
      null,
    );
    final items = result.items
        .map(
          (entry) => PortfolioShareItemProjection(
            assetSymbol: entry.item.assetSymbol,
            assetDisplayName: entry.item.assetDisplayName,
            nominalOutcome: _nominal(entry.calculation),
            sharePercent: entry.sharePercent,
            dates: _itemDates(entry.calculation, result),
            inflation: _itemInflation(
              entry.calculation,
              requested: inflationRequested,
            ),
          ),
        )
        .toList(growable: false);

    final requestedBuyCandidates = <DateTime?>[
      ...result.items.map(
        (entry) =>
            entry.calculation.requestedBuyDate ?? result.requestedBuyDate,
      ),
      ...List<DateTime?>.filled(
        result.failures.length,
        result.requestedBuyDate,
      ),
    ];
    final requestedSellCandidates = <DateTime?>[
      ...result.items.map(
        (entry) =>
            entry.calculation.requestedSellDate ?? result.requestedSellDate,
      ),
      ...List<DateTime?>.filled(
        result.failures.length,
        result.requestedSellDate,
      ),
    ];

    return PortfolioShareProjection(
      items: items,
      failureCount: result.failures.length,
      nominalOutcome: ShareNominalOutcome(
        initialValueTry: result.totalInitialValueTry,
        finalValueTry: result.totalFinalValueTry,
        profitLossTry: result.totalProfitLossTry,
        profitLossPercent: result.totalProfitLossPercent,
      ),
      dates: ShareDateEvidence(
        context: ShareDateContext.portfolio,
        requestedBuy: ShareDateValue.fromCandidates(requestedBuyCandidates),
        effectiveBuy: ShareDateValue.fromCandidates([
          ...result.items.map(
            (entry) =>
                entry.calculation.effectiveBuyDate ??
                entry.calculation.requestedBuyDate ??
                result.requestedBuyDate,
          ),
          ...failurePlaceholders,
        ]),
        requestedSell: ShareDateValue.fromCandidates(requestedSellCandidates),
        effectiveSell: ShareDateValue.fromCandidates([
          ...result.items.map(
            (entry) =>
                entry.calculation.effectiveSellDate ?? result.effectiveSellDate,
          ),
          ...failurePlaceholders,
        ]),
        calculatedAt: ShareDateValue.fromCandidates([result.calculatedAt]),
      ),
      inflation: ShareInflationEvidence.fromNullable(
        requested: inflationRequested,
        cumulativeInflationPercent: result.totalCumulativeInflationPercent,
        realProfitLossPercent: result.totalRealProfitLossPercent,
        realProfitLossTry: result.totalRealProfitLossTry,
        cpiAsOfCandidates: [
          ...result.items.map((entry) => entry.calculation.inflationDataAsOf),
          ...failurePlaceholders,
        ],
      ),
    );
  }
}

ShareNominalOutcome _nominal(PortfolioCalculation calculation) =>
    ShareNominalOutcome(
      initialValueTry: calculation.initialValueTry,
      finalValueTry: calculation.finalValueTry,
      profitLossTry: calculation.finalValueTry - calculation.initialValueTry,
      profitLossPercent: calculation.profitLossPercent,
    );

ShareDateEvidence _itemDates(
  PortfolioCalculation calculation,
  PortfolioResult result,
) {
  final requestedBuy = calculation.requestedBuyDate ?? result.requestedBuyDate;
  final requestedSell =
      calculation.requestedSellDate ?? result.requestedSellDate;
  return ShareDateEvidence(
    context: ShareDateContext.portfolio,
    requestedBuy: ShareDateValue.fromCandidates([requestedBuy]),
    effectiveBuy: ShareDateValue.fromCandidates([
      calculation.effectiveBuyDate ?? requestedBuy,
    ]),
    requestedSell: ShareDateValue.fromCandidates([requestedSell]),
    effectiveSell: ShareDateValue.fromCandidates([
      calculation.effectiveSellDate ?? result.effectiveSellDate,
    ]),
    calculatedAt: ShareDateValue.fromCandidates([
      calculation.calculatedAt ?? result.calculatedAt,
    ]),
  );
}

ShareInflationEvidence _itemInflation(
  PortfolioCalculation calculation, {
  required bool requested,
}) => ShareInflationEvidence.fromNullable(
  requested: requested,
  cumulativeInflationPercent: calculation.cumulativeInflationPercent,
  realProfitLossPercent: calculation.realProfitLossPercent,
  cpiAsOfCandidates: [calculation.inflationDataAsOf],
);
