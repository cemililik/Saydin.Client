import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Bir günün varlık fiyatı.
///
/// `price` finansal alan olduğu için `Decimal`. IEEE-754 ondalık precision
/// hatasıyla grafik tooltip'inde 1 kuruşluk fark görünmemesi için
/// CLAUDE.md "para için double YASAK" kuralı burada da geçerli — fiyat
/// tutarı tutar gibi davranır.
class ChartPoint extends Equatable {
  final DateTime date;
  final Decimal price;

  const ChartPoint({required this.date, required this.price});

  @override
  List<Object?> get props => [date, price];
}

/// Bir "ya alsaydım" hesaplamasının sonucu.
///
/// **Tip kuralı (CLAUDE.md "Yasak Listesi"):** Tüm para tutarları ve birim
/// sayıları `Decimal`'dır. `double` IEEE-754 binary olduğu için ondalık
/// toplama hatası verir (örn. `0.1 + 0.2 != 0.3`); kullanıcı 1 kuruşluk
/// fark görse uygulama güvenilirliğini kaybeder.
///
/// **Yüzde alanları (`*Percent`)** `double` olarak kalır — sadece display
/// için kullanılır, aggregasyon yok. `NumberFormat.decimalPercentPattern`
/// zaten double bekler, gereksiz Decimal cast'i UI'i karmaşıklaştırır.
class WhatIfResult extends Equatable {
  final String assetSymbol;
  final String assetDisplayName;
  final DateTime buyDate;
  final DateTime? sellDate;
  final Decimal buyPrice;
  final Decimal sellPrice;
  final Decimal unitsAcquired;
  final Decimal initialValueTry;
  final Decimal finalValueTry;
  final Decimal profitLossTry;
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
