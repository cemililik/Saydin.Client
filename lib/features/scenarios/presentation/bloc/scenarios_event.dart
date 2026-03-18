import 'package:equatable/equatable.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

abstract class ScenariosEvent extends Equatable {
  const ScenariosEvent();
}

class ScenariosRequested extends ScenariosEvent {
  final String plan;

  const ScenariosRequested({this.plan = 'free'});

  @override
  List<Object?> get props => [plan];
}

class ScenarioSaveRequested extends ScenariosEvent {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;
  final ScenarioType type;
  final Map<String, dynamic>? extraData;

  const ScenarioSaveRequested({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
    this.type = ScenarioType.whatIf,
    this.extraData,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    buyDate,
    sellDate,
    amount,
    amountType,
    type,
    extraData,
  ];
}

class ScenarioDeleteRequested extends ScenariosEvent {
  final String id;

  const ScenarioDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}
