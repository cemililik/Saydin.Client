import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'what_if_result.dart';

/// "Şu hedef kazancı bugün elde etmek için geçmişte ne kadar yatırmam
/// gerekirdi?" hesaplama sonucu.
///
/// Para alanları `Decimal` (CLAUDE.md "para için double YASAK"); yüzde
/// alanları display-only olduğu için `double`.
class ReverseWhatIfResult extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final Decimal buyPrice;
  final Decimal sellPrice;
  final Decimal requiredInvestmentTry;
  final Decimal unitsAcquired;
  final Decimal targetValueTry;
  final Decimal profitLossTry;
  final double profitLossPercent;
  final bool isProfit;
  final List<ChartPoint> priceHistory;
  final double? cumulativeInflationPercent;
  final double? realProfitLossPercent;
  final DateTime? inflationDataAsOf;
  final DateTime? actualBuyDate;
  final DateTime? actualSellDate;
  final DateTime? calculatedAt;

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
    this.calculatedAt,
  });

  /// Sonucu üreten deterministik bitiş tarihi; render anındaki saate bağlı
  /// değildir.
  DateTime get effectiveSellDate =>
      sellDate ??
      actualSellDate ??
      (priceHistory.isNotEmpty ? priceHistory.last.date : null) ??
      (calculatedAt != null
          ? DateTime(calculatedAt!.year, calculatedAt!.month, calculatedAt!.day)
          : buyDate);

  ReverseWhatIfResult withAssetDisplayName(String value) => ReverseWhatIfResult(
    assetSymbol: assetSymbol,
    assetDisplayName: value,
    buyDate: buyDate,
    sellDate: sellDate,
    buyPrice: buyPrice,
    sellPrice: sellPrice,
    requiredInvestmentTry: requiredInvestmentTry,
    unitsAcquired: unitsAcquired,
    targetValueTry: targetValueTry,
    profitLossTry: profitLossTry,
    profitLossPercent: profitLossPercent,
    isProfit: isProfit,
    priceHistory: priceHistory,
    cumulativeInflationPercent: cumulativeInflationPercent,
    realProfitLossPercent: realProfitLossPercent,
    inflationDataAsOf: inflationDataAsOf,
    actualBuyDate: actualBuyDate,
    actualSellDate: actualSellDate,
    calculatedAt: calculatedAt,
  );

  ReverseWhatIfResult withCalculatedAt(DateTime value) => ReverseWhatIfResult(
    assetSymbol: assetSymbol,
    assetDisplayName: assetDisplayName,
    buyDate: buyDate,
    sellDate: sellDate,
    buyPrice: buyPrice,
    sellPrice: sellPrice,
    requiredInvestmentTry: requiredInvestmentTry,
    unitsAcquired: unitsAcquired,
    targetValueTry: targetValueTry,
    profitLossTry: profitLossTry,
    profitLossPercent: profitLossPercent,
    isProfit: isProfit,
    priceHistory: priceHistory,
    cumulativeInflationPercent: cumulativeInflationPercent,
    realProfitLossPercent: realProfitLossPercent,
    inflationDataAsOf: inflationDataAsOf,
    actualBuyDate: actualBuyDate,
    actualSellDate: actualSellDate,
    calculatedAt: value,
  );

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
    calculatedAt,
  ];
}
