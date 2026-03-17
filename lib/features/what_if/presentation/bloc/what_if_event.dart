import 'package:equatable/equatable.dart';

abstract class WhatIfEvent extends Equatable {
  const WhatIfEvent();
  @override
  List<Object?> get props => [];
}

class WhatIfAssetsRequested extends WhatIfEvent {
  const WhatIfAssetsRequested();
}

class WhatIfSymbolChanged extends WhatIfEvent {
  final String? symbol;
  const WhatIfSymbolChanged(this.symbol);
  @override
  List<Object?> get props => [symbol];
}

class WhatIfBuyDateChanged extends WhatIfEvent {
  final DateTime? date;
  const WhatIfBuyDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class WhatIfSellDateChanged extends WhatIfEvent {
  final DateTime? date;
  const WhatIfSellDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class WhatIfAmountTypeChanged extends WhatIfEvent {
  final String amountType;
  const WhatIfAmountTypeChanged(this.amountType);
  @override
  List<Object?> get props => [amountType];
}

/// Kaydedilmiş senaryoyu yeniden hesaplar: formu doldurur + calculate tetikler.
class WhatIfReplayRequested extends WhatIfEvent {
  final String assetSymbol;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;

  const WhatIfReplayRequested({
    required this.assetSymbol,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    buyDate,
    sellDate,
    amount,
    amountType,
  ];
}

class WhatIfInflationToggled extends WhatIfEvent {
  const WhatIfInflationToggled();
}

class WhatIfCalculateRequested extends WhatIfEvent {
  final String assetSymbol;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;
  final bool includeInflation;

  const WhatIfCalculateRequested({
    required this.assetSymbol,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
    this.includeInflation = false,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    buyDate,
    sellDate,
    amount,
    amountType,
    includeInflation,
  ];
}
