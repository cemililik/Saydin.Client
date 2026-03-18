import 'package:equatable/equatable.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

/// Tek bir kalemin hesaplama sonucu + portföydeki payı.
class PortfolioItemResult extends Equatable {
  final PortfolioItem item;
  final WhatIfResult result;

  /// Son değer üzerinden hesaplanan portföy payı (0-100).
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
class PortfolioResult extends Equatable {
  final List<PortfolioItemResult> items;
  final double totalInitialValueTry;
  final double totalFinalValueTry;
  final double totalProfitLossTry;
  final double totalProfitLossPercent;
  final bool isProfit;

  // Enflasyon düzeltmesi — null ise hesaplanmadı / aktif değil
  final double? totalRealProfitLossTry;
  final double? totalRealProfitLossPercent;
  final double? totalCumulativeInflationPercent;

  const PortfolioResult({
    required this.items,
    required this.totalInitialValueTry,
    required this.totalFinalValueTry,
    required this.totalProfitLossTry,
    required this.totalProfitLossPercent,
    required this.isProfit,
    this.totalRealProfitLossTry,
    this.totalRealProfitLossPercent,
    this.totalCumulativeInflationPercent,
  });

  bool get hasInflation => totalRealProfitLossPercent != null;

  @override
  List<Object?> get props => [
    items,
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
