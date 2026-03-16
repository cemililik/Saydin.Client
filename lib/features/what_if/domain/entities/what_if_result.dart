import 'package:equatable/equatable.dart';

class WhatIfResult extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final double buyPrice;
  final double sellPrice;
  final double unitsAcquired;
  final double initialValueTry;
  final double finalValueTry;
  final double profitLossTry;
  final double profitLossPercent;
  final bool isProfit;

  const WhatIfResult({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.buyPrice,
    required this.sellPrice,
    required this.unitsAcquired,
    required this.initialValueTry,
    required this.finalValueTry,
    required this.profitLossTry,
    required this.profitLossPercent,
    required this.isProfit,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    buyDate,
    sellDate,
    buyPrice,
    sellPrice,
    unitsAcquired,
    initialValueTry,
    finalValueTry,
    profitLossTry,
    profitLossPercent,
    isProfit,
  ];
}
