import '../../domain/entities/what_if_result.dart';

class WhatIfResponseModel extends WhatIfResult {
  WhatIfResponseModel({
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
  });

  factory WhatIfResponseModel.fromJson(Map<String, dynamic> json) =>
      WhatIfResponseModel(
        assetSymbol: json['assetSymbol'] as String,
        assetDisplayName: json['assetDisplayName'] as String,
        buyDate: DateTime.parse(json['buyDate'] as String),
        sellDate: json['sellDate'] != null
            ? DateTime.parse(json['sellDate'] as String)
            : null,
        buyPrice: json['buyPrice'] as num,
        sellPrice: json['sellPrice'] as num,
        unitsAcquired: json['unitsAcquired'] as num,
        initialValueTry: json['initialValueTry'] as num,
        finalValueTry: json['finalValueTry'] as num,
        profitLossTry: json['profitLossTry'] as num,
        profitLossPercent: json['profitLossPercent'] as num,
        isProfit: json['isProfit'] as bool,
      );
}
