import 'package:equatable/equatable.dart';
import 'package:saydin/core/share/share_card_contract.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';

final class PortfolioShareItemProjection extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final ShareNominalOutcome nominalOutcome;
  final double sharePercent;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  const PortfolioShareItemProjection({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.nominalOutcome,
    required this.sharePercent,
    required this.dates,
    required this.inflation,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    nominalOutcome,
    sharePercent,
    dates,
    inflation,
  ];
}

/// Share-ready portfolio aggregate with explicit partial-result evidence.
final class PortfolioShareProjection extends Equatable
    implements ShareCardProjection {
  final List<PortfolioShareItemProjection> items;
  final int failureCount;
  final ShareNominalOutcome nominalOutcome;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  PortfolioShareProjection({
    required List<PortfolioShareItemProjection> items,
    required this.failureCount,
    required this.nominalOutcome,
    required this.dates,
    required this.inflation,
  }) : items = List.unmodifiable(items);

  @override
  ShareCardVariant get shareCardVariant => ShareCardVariant.portfolio;

  bool get isPartial => failureCount > 0;

  @override
  List<Object?> get props => [
    items,
    failureCount,
    nominalOutcome,
    dates,
    inflation,
  ];
}
