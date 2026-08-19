import 'package:equatable/equatable.dart';
import 'package:saydin/core/share/share_card_contract.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';

/// Share-ready financial snapshot for a forward "what if" calculation.
///
/// Strings are raw domain identifiers/names. Localization and formatting stay
/// in presentation so this contract remains pure Dart.
final class WhatIfShareProjection extends Equatable
    implements ShareCardProjection {
  final String assetSymbol;
  final String assetDisplayName;
  final ShareNominalOutcome nominalOutcome;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  const WhatIfShareProjection({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.nominalOutcome,
    required this.dates,
    required this.inflation,
  });

  @override
  ShareCardVariant get shareCardVariant => ShareCardVariant.whatIf;

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    nominalOutcome,
    dates,
    inflation,
  ];
}

/// Share-ready snapshot for a reverse target calculation.
final class ReverseWhatIfShareProjection extends Equatable
    implements ShareCardProjection {
  final String assetSymbol;
  final String assetDisplayName;
  final ShareNominalOutcome nominalOutcome;
  final ShareDateEvidence dates;
  final ShareInflationEvidence inflation;

  const ReverseWhatIfShareProjection({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.nominalOutcome,
    required this.dates,
    required this.inflation,
  });

  @override
  ShareCardVariant get shareCardVariant => ShareCardVariant.reverseWhatIf;

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    nominalOutcome,
    dates,
    inflation,
  ];
}
