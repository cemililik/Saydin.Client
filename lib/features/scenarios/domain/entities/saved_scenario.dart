import 'package:equatable/equatable.dart';

class SavedScenario extends Equatable {
  final String id;
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;
  final String? label;
  final DateTime createdAt;

  const SavedScenario({
    required this.id,
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
    this.label,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    assetSymbol,
    assetDisplayName,
    buyDate,
    sellDate,
    amount,
    amountType,
    label,
    createdAt,
  ];
}
