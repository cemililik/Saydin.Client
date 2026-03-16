class WhatIfResult {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num buyPrice;
  final num sellPrice;
  final num unitsAcquired;
  final num initialValueTry;
  final num finalValueTry;
  final num profitLossTry;
  final num profitLossPercent;
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
}
