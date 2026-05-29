import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

/// Tek bir kalemin hesaplama sonucu + portföydeki payı.
class PortfolioItemResult extends Equatable {
  final PortfolioItem item;
  final WhatIfResult result;

  /// Son değer üzerinden hesaplanan portföy payı (0-100).
  /// Yüzde display-only — double yeterli, Decimal gereksiz precision.
  final double sharePercent;

  const PortfolioItemResult({
    required this.item,
    required this.result,
    required this.sharePercent,
  });

  @override
  List<Object?> get props => [item, result, sharePercent];
}

/// Tüm portföy hesaplama sonucu.
///
/// Bir veya birden çok kalem hesaplanamazsa, başarılı kalemler [items]
/// içinde dönerken başarısız olanlar [failedItems]'a düşer ve UI
/// kullanıcıya "X kalem hesaplanamadı" mesajı gösterir. Eski `Future.wait`
/// fail-fast davranışı tek bir item çökünce tüm hesabı çökertir ve quota
/// (5 paralel HTTP) boşa harcanırdı.
///
/// **Tip kuralı:** Para alanları `Decimal` (CLAUDE.md "para için double
/// YASAK"); yüzde alanları display-only olduğu için `double`.
class PortfolioResult extends Equatable {
  final List<PortfolioItemResult> items;

  /// Hesaplama sırasında başarısız olan kalemler. UI bunları kullanıcıya
  /// "yeniden dene" akışıyla sunabilir. Tüm kalemler başarılı ise boş liste.
  final List<PortfolioItem> failedItems;

  final Decimal totalInitialValueTry;
  final Decimal totalFinalValueTry;
  final Decimal totalProfitLossTry;
  final double totalProfitLossPercent;
  final bool isProfit;

  // Enflasyon düzeltmesi — null ise hesaplanmadı / aktif değil
  final Decimal? totalRealProfitLossTry;
  final double? totalRealProfitLossPercent;
  final double? totalCumulativeInflationPercent;

  const PortfolioResult({
    required this.items,
    required this.totalInitialValueTry,
    required this.totalFinalValueTry,
    required this.totalProfitLossTry,
    required this.totalProfitLossPercent,
    required this.isProfit,
    this.failedItems = const [],
    this.totalRealProfitLossTry,
    this.totalRealProfitLossPercent,
    this.totalCumulativeInflationPercent,
  });

  bool get hasInflation => totalRealProfitLossPercent != null;

  /// Bir veya daha fazla kalem hesaplanamadıysa true.
  bool get hasPartialFailure => failedItems.isNotEmpty;

  @override
  List<Object?> get props => [
    items,
    failedItems,
    totalInitialValueTry,
    totalFinalValueTry,
    totalProfitLossTry,
    totalProfitLossPercent,
    isProfit,
    totalRealProfitLossTry,
    totalRealProfitLossPercent,
    totalCumulativeInflationPercent,
  ];
}
