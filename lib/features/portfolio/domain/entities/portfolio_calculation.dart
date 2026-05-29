import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';

/// Tek bir portföy kaleminin hesaplama sonucu — **portföye ait** saf domain
/// entity'si.
///
/// Önceden portföy doğrudan `WhatIfResult`'ı gömüyordu (F-09-19: cross-feature
/// domain coupling). Artık portföy yalnızca kendi ihtiyaç duyduğu alanları
/// taşıyan bu entity'yi kullanır; `WhatIfResult` → `PortfolioCalculation`
/// dönüşümü **data katmanında** (`PortfolioRepositoryImpl`) yapılır, böylece
/// portföy domain'i What-If domain'inden bağımsızdır.
///
/// **Tip kuralı:** Para alanları `Decimal` (CLAUDE.md "para için double
/// YASAK"); yüzde alanları display-only olduğu için `double`.
class PortfolioCalculation extends Equatable {
  final Decimal initialValueTry;
  final Decimal finalValueTry;
  final double profitLossPercent;
  final bool isProfit;

  /// Enflasyon düzeltmesi — null ise hesaplanmadı / kapalıydı.
  final double? cumulativeInflationPercent;
  final double? realProfitLossPercent;

  const PortfolioCalculation({
    required this.initialValueTry,
    required this.finalValueTry,
    required this.profitLossPercent,
    required this.isProfit,
    this.cumulativeInflationPercent,
    this.realProfitLossPercent,
  });

  @override
  List<Object?> get props => [
    initialValueTry,
    finalValueTry,
    profitLossPercent,
    isProfit,
    cumulativeInflationPercent,
    realProfitLossPercent,
  ];
}

/// Bir kalemin hesaplama sonucu (girdi [item] + sonuç [calculation]).
///
/// [calculation] `null` ise bu kalem hesaplanamadı (örn. backend geçici 503) —
/// repository per-item izolasyonu sayesinde diğer kalemler etkilenmez; use
/// case bu kalemi `failedItems`'a düşürür (partial-success akışı).
class PortfolioItemOutcome extends Equatable {
  final PortfolioItem item;
  final PortfolioCalculation? calculation;

  const PortfolioItemOutcome({required this.item, this.calculation});

  bool get isSuccess => calculation != null;

  @override
  List<Object?> get props => [item, calculation];
}
