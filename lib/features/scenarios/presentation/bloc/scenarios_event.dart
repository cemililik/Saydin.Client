import 'package:equatable/equatable.dart';

abstract class ScenariosEvent extends Equatable {
  const ScenariosEvent();
}

class ScenariosRequested extends ScenariosEvent {
  const ScenariosRequested();

  @override
  List<Object?> get props => [];
}

class ScenarioSaveRequested extends ScenariosEvent {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;

  const ScenarioSaveRequested({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    buyDate,
    sellDate,
    amount,
    amountType,
  ];
}

class ScenarioDeleteRequested extends ScenariosEvent {
  final String id;

  const ScenarioDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}
