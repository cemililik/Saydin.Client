import 'package:equatable/equatable.dart';

class ChartPoint extends Equatable {
  final DateTime date;
  final double price;

  const ChartPoint({required this.date, required this.price});

  @override
  List<Object?> get props => [date, price];
}

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
  final List<ChartPoint> priceHistory;
  // Enflasyon düzeltmesi — backend'den null gelirse özellik kapalıydı
  final double? cumulativeInflationPercent;
  final double? realProfitLossPercent;
  // TÜİK gecikmesi: kullanılan endeks tarihi istenen satış ayından eskiyse dolu
  final DateTime? inflationDataAsOf;
  // Haftasonu/tatil: kullanıcının seçtiği tarih yerine kullanılan gerçek işlem günü
  final DateTime? actualBuyDate;
  final DateTime? actualSellDate;

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
    this.priceHistory = const [],
    this.cumulativeInflationPercent,
    this.realProfitLossPercent,
    this.inflationDataAsOf,
    this.actualBuyDate,
    this.actualSellDate,
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
    priceHistory,
    cumulativeInflationPercent,
    realProfitLossPercent,
    inflationDataAsOf,
    actualBuyDate,
    actualSellDate,
  ];
}
