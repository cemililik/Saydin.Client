import '../../domain/entities/what_if_result.dart';

class WhatIfResponseModel extends WhatIfResult {
  const WhatIfResponseModel({
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.buyDate,
    super.sellDate,
    required super.buyPrice,
    required super.sellPrice,
    required super.unitsAcquired,
    required super.initialValueTry,
    required super.finalValueTry,
    required super.profitLossTry,
    required super.profitLossPercent,
    required super.isProfit,
    super.priceHistory,
  });

  factory WhatIfResponseModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['priceHistory'] as List<dynamic>? ?? [];
    final priceHistory = rawHistory.map((e) {
      final map = e as Map<String, dynamic>;
      return ChartPoint(
        date: DateTime.parse(map['date'] as String),
        price: (map['price'] as num).toDouble(),
      );
    }).toList();

    return WhatIfResponseModel(
      assetSymbol: json['assetSymbol'] as String,
      assetDisplayName: json['assetDisplayName'] as String,
      buyDate: DateTime.parse(json['buyDate'] as String),
      sellDate: json['sellDate'] != null
          ? DateTime.parse(json['sellDate'] as String)
          : null,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      unitsAcquired: (json['unitsAcquired'] as num).toDouble(),
      initialValueTry: (json['initialValueTry'] as num).toDouble(),
      finalValueTry: (json['finalValueTry'] as num).toDouble(),
      profitLossTry: (json['profitLossTry'] as num).toDouble(),
      profitLossPercent: (json['profitLossPercent'] as num).toDouble(),
      isProfit: json['isProfit'] as bool,
      priceHistory: priceHistory,
    );
  }
}
