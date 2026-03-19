import '../../domain/entities/reverse_what_if_result.dart';
import '../../domain/entities/what_if_result.dart';

class ReverseWhatIfResponseModel extends ReverseWhatIfResult {
  const ReverseWhatIfResponseModel({
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.buyDate,
    super.sellDate,
    required super.buyPrice,
    required super.sellPrice,
    required super.requiredInvestmentTry,
    required super.unitsAcquired,
    required super.targetValueTry,
    required super.profitLossTry,
    required super.profitLossPercent,
    required super.isProfit,
    super.priceHistory,
    super.cumulativeInflationPercent,
    super.realProfitLossPercent,
    super.inflationDataAsOf,
    super.actualBuyDate,
    super.actualSellDate,
  });

  factory ReverseWhatIfResponseModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['priceHistory'] as List<dynamic>? ?? [];
    final priceHistory = rawHistory.map((e) {
      final map = e as Map<String, dynamic>;
      return ChartPoint(
        date: DateTime.parse(map['date'] as String),
        price: (map['price'] as num).toDouble(),
      );
    }).toList();

    return ReverseWhatIfResponseModel(
      assetSymbol: json['assetSymbol'] as String,
      assetDisplayName: json['assetDisplayName'] as String,
      buyDate: DateTime.parse(json['buyDate'] as String),
      sellDate: json['sellDate'] != null
          ? DateTime.parse(json['sellDate'] as String)
          : null,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      requiredInvestmentTry: (json['requiredInvestmentTry'] as num).toDouble(),
      unitsAcquired: (json['unitsAcquired'] as num).toDouble(),
      targetValueTry: (json['targetValueTry'] as num).toDouble(),
      profitLossTry: (json['profitLossTry'] as num).toDouble(),
      profitLossPercent: (json['profitLossPercent'] as num).toDouble(),
      isProfit: json['isProfit'] as bool,
      priceHistory: priceHistory,
      cumulativeInflationPercent: (json['cumulativeInflationPercent'] as num?)
          ?.toDouble(),
      realProfitLossPercent: (json['realProfitLossPercent'] as num?)
          ?.toDouble(),
      inflationDataAsOf: json['inflationDataAsOf'] != null
          ? DateTime.parse(json['inflationDataAsOf'] as String)
          : null,
      actualBuyDate: json['actualBuyDate'] != null
          ? DateTime.parse(json['actualBuyDate'] as String)
          : null,
      actualSellDate: json['actualSellDate'] != null
          ? DateTime.parse(json['actualSellDate'] as String)
          : null,
    );
  }
}
