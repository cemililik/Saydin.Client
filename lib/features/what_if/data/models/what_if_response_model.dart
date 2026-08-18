import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/core/utils/profit_direction_validator.dart';
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
    super.cumulativeInflationPercent,
    super.realProfitLossPercent,
    super.inflationDataAsOf,
    super.actualBuyDate,
    super.actualSellDate,
  });

  factory WhatIfResponseModel.fromJson(Map<String, dynamic> json) {
    final profitLossTry = MoneyParser.requireDecimal(
      json['profitLossTry'],
      'profitLossTry',
    );
    final rawHistory = json['priceHistory'] as List<dynamic>? ?? [];
    final priceHistory = rawHistory.map((e) {
      final map = e as Map<String, dynamic>;
      return ChartPoint(
        date: DateTime.parse(map['date'] as String),
        price: MoneyParser.requireDecimal(map['price'], 'priceHistory.price'),
      );
    }).toList();

    return WhatIfResponseModel(
      assetSymbol: json['assetSymbol'] as String,
      assetDisplayName: json['assetDisplayName'] as String,
      buyDate: DateTime.parse(json['buyDate'] as String),
      sellDate: json['sellDate'] != null
          ? DateTime.parse(json['sellDate'] as String)
          : null,
      buyPrice: MoneyParser.requireDecimal(json['buyPrice'], 'buyPrice'),
      sellPrice: MoneyParser.requireDecimal(json['sellPrice'], 'sellPrice'),
      unitsAcquired: MoneyParser.requireDecimal(
        json['unitsAcquired'],
        'unitsAcquired',
      ),
      initialValueTry: MoneyParser.requireDecimal(
        json['initialValueTry'],
        'initialValueTry',
      ),
      finalValueTry: MoneyParser.requireDecimal(
        json['finalValueTry'],
        'finalValueTry',
      ),
      profitLossTry: profitLossTry,
      profitLossPercent: (json['profitLossPercent'] as num).toDouble(),
      isProfit: ProfitDirectionValidator.derive(
        rawIsProfit: json['isProfit'],
        profitLossTry: profitLossTry,
        context: 'what-if response',
      ),
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
