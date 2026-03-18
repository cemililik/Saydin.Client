import 'package:equatable/equatable.dart';

class DcaPurchase extends Equatable {
  final DateTime date;
  final double price;
  final double unitsAcquired;
  final double cumulativeUnits;
  final double cumulativeCostTry;
  final double cumulativeValueTry;

  const DcaPurchase({
    required this.date,
    required this.price,
    required this.unitsAcquired,
    required this.cumulativeUnits,
    required this.cumulativeCostTry,
    required this.cumulativeValueTry,
  });

  @override
  List<Object?> get props => [
    date,
    price,
    unitsAcquired,
    cumulativeUnits,
    cumulativeCostTry,
    cumulativeValueTry,
  ];
}

class DcaChartPoint extends Equatable {
  final DateTime date;
  final double cumulativeCost;
  final double cumulativeValue;

  const DcaChartPoint({
    required this.date,
    required this.cumulativeCost,
    required this.cumulativeValue,
  });

  @override
  List<Object?> get props => [date, cumulativeCost, cumulativeValue];
}

class DcaResult extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime startDate;
  final DateTime endDate;
  final String period;
  final double periodicAmount;
  final int totalPurchases;
  final double totalInvestedTry;
  final double currentValueTry;
  final double profitLossTry;
  final double profitLossPercent;
  final bool isProfit;
  final double averageCostPerUnit;
  final double totalUnitsAcquired;
  final double currentUnitPrice;
  // Enflasyon düzeltmesi — backend'den null gelirse özellik kapalıydı
  final double? cumulativeInflationPercent;
  final double? realProfitLossPercent;
  final DateTime? inflationDataAsOf;
  final List<DcaPurchase> purchases;
  final List<DcaChartPoint> chartData;

  const DcaResult({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.periodicAmount,
    required this.totalPurchases,
    required this.totalInvestedTry,
    required this.currentValueTry,
    required this.profitLossTry,
    required this.profitLossPercent,
    required this.isProfit,
    required this.averageCostPerUnit,
    required this.totalUnitsAcquired,
    required this.currentUnitPrice,
    this.cumulativeInflationPercent,
    this.realProfitLossPercent,
    this.inflationDataAsOf,
    this.purchases = const [],
    this.chartData = const [],
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    startDate,
    endDate,
    period,
    periodicAmount,
    totalPurchases,
    totalInvestedTry,
    currentValueTry,
    profitLossTry,
    profitLossPercent,
    isProfit,
    averageCostPerUnit,
    totalUnitsAcquired,
    currentUnitPrice,
    cumulativeInflationPercent,
    realProfitLossPercent,
    inflationDataAsOf,
    purchases,
    chartData,
  ];
}
