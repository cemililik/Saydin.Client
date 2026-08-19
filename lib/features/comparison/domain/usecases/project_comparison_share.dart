import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/entities/comparison_share_projection.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

/// Projects every comparison row from the same immutable response snapshot.
final class ComparisonShareProjector {
  const ComparisonShareProjector();

  ComparisonShareProjection call(
    CompareResult result, {
    required bool inflationRequested,
    required ComparisonShareReturnMode returnMode,
  }) {
    final calculations = result.results
        .map((item) => item.calculation)
        .toList(growable: false);
    final sourceItems = result.results
        .map(
          (item) => ComparisonShareItemProjection(
            sourceRank: item.rank,
            displayRank: null,
            assetSymbol: item.calculation.assetSymbol,
            assetDisplayName: item.calculation.assetDisplayName,
            nominalOutcome: _nominal(item.calculation),
            dates: _dates(item.calculation),
            inflation: _inflation(
              item.calculation,
              requested: inflationRequested,
            ),
          ),
        )
        .toList(growable: false);
    final ranked = _rankForMode(sourceItems, returnMode);

    return ComparisonShareProjection(
      returnMode: returnMode,
      rankingBasis: ranked.basis,
      items: ranked.items,
      dates: ShareDateEvidence(
        context: ShareDateContext.trade,
        requestedBuy: ShareDateValue.fromCandidates(
          calculations.map((calculation) => calculation.buyDate),
        ),
        effectiveBuy: ShareDateValue.fromCandidates(
          calculations.map(
            (calculation) => calculation.actualBuyDate ?? calculation.buyDate,
          ),
        ),
        requestedSell: ShareDateValue.fromCandidates(
          calculations.map((calculation) => calculation.sellDate),
        ),
        effectiveSell: ShareDateValue.fromCandidates(
          calculations.map(_effectiveSellDate),
        ),
        calculatedAt: ShareDateValue.fromCandidates(
          calculations.map((calculation) => calculation.calculatedAt),
        ),
      ),
      cpiAsOf: ShareDateValue.fromCandidates(
        calculations.map((calculation) => calculation.inflationDataAsOf),
      ),
    );
  }
}

({ComparisonShareRankingBasis basis, List<ComparisonShareItemProjection> items})
_rankForMode(
  List<ComparisonShareItemProjection> items,
  ComparisonShareReturnMode mode,
) {
  if (mode == ComparisonShareReturnMode.nominal) {
    final sorted = [...items]
      ..sort((left, right) {
        final byReturn = right.nominalOutcome.profitLossPercent.compareTo(
          left.nominalOutcome.profitLossPercent,
        );
        return byReturn != 0
            ? byReturn
            : left.sourceRank.compareTo(right.sourceRank);
      });
    return (
      basis: ComparisonShareRankingBasis.nominalProfitLossPercent,
      items: [
        for (final (index, item) in sorted.indexed)
          item.withDisplayRank(index + 1),
      ],
    );
  }

  final available =
      items
          .where((item) => item.inflation.realProfitLossPercent.isAvailable)
          .toList(growable: false)
        ..sort((left, right) {
          final byReturn = right.inflation.realProfitLossPercent.value!
              .compareTo(left.inflation.realProfitLossPercent.value!);
          return byReturn != 0
              ? byReturn
              : left.sourceRank.compareTo(right.sourceRank);
        });
  final unavailable =
      items
          .where((item) => !item.inflation.realProfitLossPercent.isAvailable)
          .toList(growable: false)
        ..sort((left, right) => left.sourceRank.compareTo(right.sourceRank));

  if (available.isEmpty) {
    return (
      basis: ComparisonShareRankingBasis.unavailable,
      items: unavailable
          .map((item) => item.withDisplayRank(null))
          .toList(growable: false),
    );
  }

  return (
    basis: ComparisonShareRankingBasis.realProfitLossPercentAvailableSubset,
    items: [
      for (final (index, item) in available.indexed)
        item.withDisplayRank(index + 1),
      ...unavailable.map((item) => item.withDisplayRank(null)),
    ],
  );
}

ShareNominalOutcome _nominal(WhatIfResult result) => ShareNominalOutcome(
  initialValueTry: result.initialValueTry,
  finalValueTry: result.finalValueTry,
  profitLossTry: result.profitLossTry,
  profitLossPercent: result.profitLossPercent,
);

ShareDateEvidence _dates(WhatIfResult result) => ShareDateEvidence(
  context: ShareDateContext.trade,
  requestedBuy: ShareDateValue.single(result.buyDate),
  effectiveBuy: ShareDateValue.single(result.actualBuyDate ?? result.buyDate),
  requestedSell: ShareDateValue.fromCandidates([result.sellDate]),
  effectiveSell: ShareDateValue.single(_effectiveSellDate(result)),
  calculatedAt: ShareDateValue.fromCandidates([result.calculatedAt]),
);

ShareInflationEvidence _inflation(
  WhatIfResult result, {
  required bool requested,
}) => ShareInflationEvidence.fromNullable(
  requested: requested,
  cumulativeInflationPercent: result.cumulativeInflationPercent,
  realProfitLossPercent: result.realProfitLossPercent,
  cpiAsOfCandidates: [result.inflationDataAsOf],
);

DateTime _effectiveSellDate(WhatIfResult result) {
  if (result.actualSellDate != null) return result.actualSellDate!;
  if (result.sellDate != null) return result.sellDate!;
  if (result.priceHistory.isNotEmpty) {
    return result.priceHistory
        .map((point) => point.date)
        .reduce((left, right) => right.isAfter(left) ? right : left);
  }
  if (result.calculatedAt != null) {
    final value = result.calculatedAt!;
    return DateTime(value.year, value.month, value.day);
  }
  return result.buyDate;
}
