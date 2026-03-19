import 'package:equatable/equatable.dart';
import 'what_if_result.dart';

class ReverseWhatIfResult extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final double buyPrice;
  final double sellPrice;
  final double requiredInvestmentTry;
  final double unitsAcquired;
  final double targetValueTry;
  final double profitLossTry;
  final double profitLossPercent;
  final bool isProfit;
  final List<ChartPoint> priceHistory;
  final double? cumulativeInflationPercent;
  final double? realProfitLossPercent;
  final DateTime? inflationDataAsOf;
  final DateTime? actualBuyDate;
  final DateTime? actualSellDate;

  const ReverseWhatIfResult({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.buyDate,
    this.sellDate,
    required this.buyPrice,
    required this.sellPrice,
    required this.requiredInvestmentTry,
    required this.unitsAcquired,
    required this.targetValueTry,
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
    requiredInvestmentTry,
    unitsAcquired,
    targetValueTry,
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
