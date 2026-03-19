import '../../domain/entities/dca_result.dart';

class DcaResponseModel extends DcaResult {
  const DcaResponseModel({
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.startDate,
    required super.endDate,
    required super.period,
    required super.periodicAmount,
    required super.totalPurchases,
    required super.totalInvestedTry,
    required super.currentValueTry,
    required super.profitLossTry,
    required super.profitLossPercent,
    required super.isProfit,
    required super.averageCostPerUnit,
    required super.totalUnitsAcquired,
    required super.currentUnitPrice,
    super.cumulativeInflationPercent,
    super.realProfitLossPercent,
    super.inflationDataAsOf,
    super.purchases,
    super.chartData,
  });

  factory DcaResponseModel.fromJson(Map<String, dynamic> json) {
    final rawPurchases = json['purchases'] as List<dynamic>? ?? [];
    final purchases = rawPurchases.map((e) {
      final map = e as Map<String, dynamic>;
      return DcaPurchase(
        date: DateTime.parse(map['date'] as String),
        price: (map['price'] as num).toDouble(),
        unitsAcquired: (map['unitsAcquired'] as num).toDouble(),
        cumulativeUnits: (map['cumulativeUnits'] as num).toDouble(),
        cumulativeCostTry: (map['cumulativeCostTry'] as num).toDouble(),
        cumulativeValueTry: (map['cumulativeValueTry'] as num).toDouble(),
      );
    }).toList();

    final rawChart = json['chartData'] as List<dynamic>? ?? [];
    final chartData = rawChart.map((e) {
      final map = e as Map<String, dynamic>;
      return DcaChartPoint(
        date: DateTime.parse(map['date'] as String),
        cumulativeCost: (map['cumulativeCost'] as num).toDouble(),
        cumulativeValue: (map['cumulativeValue'] as num).toDouble(),
      );
    }).toList();

    return DcaResponseModel(
      assetSymbol: json['assetSymbol'] as String,
      assetDisplayName: json['assetDisplayName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      period: json['period'] as String,
      periodicAmount: (json['periodicAmount'] as num).toDouble(),
      totalPurchases: json['totalPurchases'] as int,
      totalInvestedTry: (json['totalInvestedTry'] as num).toDouble(),
      currentValueTry: (json['currentValueTry'] as num).toDouble(),
      profitLossTry: (json['profitLossTry'] as num).toDouble(),
      profitLossPercent: (json['profitLossPercent'] as num).toDouble(),
      isProfit: json['isProfit'] as bool,
      averageCostPerUnit: (json['averageCostPerUnit'] as num).toDouble(),
      totalUnitsAcquired: (json['totalUnitsAcquired'] as num).toDouble(),
      currentUnitPrice: (json['currentUnitPrice'] as num).toDouble(),
      cumulativeInflationPercent: (json['cumulativeInflationPercent'] as num?)
          ?.toDouble(),
      realProfitLossPercent: (json['realProfitLossPercent'] as num?)
          ?.toDouble(),
      inflationDataAsOf: json['inflationDataAsOf'] != null
          ? DateTime.parse(json['inflationDataAsOf'] as String)
          : null,
      purchases: purchases,
      chartData: chartData,
    );
  }
}
