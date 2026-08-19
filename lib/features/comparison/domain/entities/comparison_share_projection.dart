import 'package:equatable/equatable.dart';
import 'package:saydin/core/share/share_card_contract.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';

/// Explicit return basis presented for comparison items.
enum ComparisonShareReturnMode { nominal, real }

/// Provenance of the rank visible on the share projection.
enum ComparisonShareRankingBasis {
  /// Locally ranked nominal profit/loss percentages.
  nominalProfitLossPercent,

  /// Locally ranked real-return rows; missing real values remain unranked.
  realProfitLossPercentAvailableSubset,

  /// No item had real-return evidence, so no display rank exists.
  unavailable,
}

final class ComparisonShareItemProjection extends Equatable {
  /// Original backend rank retained as evidence; never relabelled as real.
  final int sourceRank;

  /// Rank for [ComparisonShareProjection.returnMode]. Null means unavailable.
  final int? displayRank;
  final String assetSymbol;
  final String assetDisplayName;
  final ShareNominalOutcome nominalOutcome;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  const ComparisonShareItemProjection({
    required this.sourceRank,
    required this.displayRank,
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.nominalOutcome,
    required this.dates,
    required this.inflation,
  });

  SharePercentEvidence returnFor(ComparisonShareReturnMode mode) =>
      switch (mode) {
        ComparisonShareReturnMode.nominal => SharePercentEvidence.available(
          nominalOutcome.profitLossPercent,
        ),
        ComparisonShareReturnMode.real => inflation.realProfitLossPercent,
      };

  ComparisonShareItemProjection withDisplayRank(int? value) =>
      ComparisonShareItemProjection(
        sourceRank: sourceRank,
        displayRank: value,
        assetSymbol: assetSymbol,
        assetDisplayName: assetDisplayName,
        nominalOutcome: nominalOutcome,
        dates: dates,
        inflation: inflation,
      );

  @override
  List<Object?> get props => [
    sourceRank,
    displayRank,
    assetSymbol,
    assetDisplayName,
    nominalOutcome,
    dates,
    inflation,
  ];
}

/// Comparison projection keeps both display and ranking bases explicit.
final class ComparisonShareProjection extends Equatable
    implements ShareCardProjection {
  final ComparisonShareReturnMode returnMode;
  final ComparisonShareRankingBasis rankingBasis;
  final List<ComparisonShareItemProjection> items;
  final ShareDateEvidence dates;
  final ShareDateValue cpiAsOf;

  ComparisonShareProjection({
    required this.returnMode,
    required this.rankingBasis,
    required List<ComparisonShareItemProjection> items,
    required this.dates,
    required this.cpiAsOf,
  }) : items = List.unmodifiable(items);

  @override
  ShareCardVariant get shareCardVariant => ShareCardVariant.comparison;

  @override
  List<Object?> get props => [returnMode, rankingBasis, items, dates, cpiAsOf];
}
