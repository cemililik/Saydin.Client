import 'package:equatable/equatable.dart';

enum ScenarioType { whatIf, comparison, portfolio }

class SavedScenario extends Equatable {
  final String id;
  final ScenarioType type;
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;
  final String? label;
  final DateTime createdAt;

  /// Tipe özgü ek veriler (karşılaştırma için kazanan, portföy için getiri vb.)
  final Map<String, dynamic>? extraData;

  const SavedScenario({
    required this.id,
    this.type = ScenarioType.whatIf,
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
    this.label,
    required this.createdAt,
    this.extraData,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    assetSymbol,
    assetDisplayName,
    buyDate,
    sellDate,
    amount,
    amountType,
    label,
    createdAt,
    extraData,
  ];
}
