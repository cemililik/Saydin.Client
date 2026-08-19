import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:saydin/core/share/share_card_contract.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';

/// Share-ready financial snapshot for a recurring investment calculation.
final class DcaShareProjection extends Equatable
    implements ShareCardProjection {
  final String assetSymbol;
  final String assetDisplayName;
  final String period;
  final Decimal periodicAmount;
  final int totalPurchases;
  final ShareNominalOutcome nominalOutcome;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  const DcaShareProjection({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.period,
    required this.periodicAmount,
    required this.totalPurchases,
    required this.nominalOutcome,
    required this.dates,
    required this.inflation,
  });

  @override
  ShareCardVariant get shareCardVariant => ShareCardVariant.dca;

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    period,
    periodicAmount,
    totalPurchases,
    nominalOutcome,
    dates,
    inflation,
  ];
}
