import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

abstract class ScenariosEvent extends Equatable {
  const ScenariosEvent();
}

class ScenariosRequested extends ScenariosEvent {
  final String plan;

  /// `RefreshIndicator` gibi UI çağıranlarının yalnız kendi başlattığı
  /// isteğin terminal durumunu bekleyebilmesi için opsiyonel completion.
  /// BLoC event handler'ları eşzamanlı çalışabildiğinden state stream'indeki
  /// ilk `Loaded/Failure`ı beklemek başka bir isteğin sonucuyla erken
  /// tamamlanabilirdi.
  final Completer<void>? completion;

  const ScenariosRequested({this.plan = 'free', this.completion});

  @override
  List<Object?> get props => [plan];
}

/// `amount` uçtan uca `Decimal` taşır. Senaryo kaydı hesaplama snapshot'ını
/// backend'e gönderdiği için form/controller veya display dönüşümlerinden
/// türetilmiş `double` kullanılmaz.
class ScenarioSaveRequested extends ScenariosEvent {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final Decimal amount;
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
  final Completer<bool>? completion;

  const ScenarioDeleteRequested(this.id, {this.completion});

  @override
  List<Object?> get props => [id];
}
