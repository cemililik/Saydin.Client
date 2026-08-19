import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
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

  FinancialOutcome get outcome =>
      FinancialOutcome.fromAmount(finalValueTry - initialValueTry);

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
/// Sonuç yalnız iki production-safe varyanttan biridir: hesaplanan kalem
/// [PortfolioItemCalculatedOutcome], başarısız kalem ise typed [AppError]
/// taşıyan [PortfolioItemErrorOutcome]. Böylece partial-success nedeni data
/// sınırında kaybolmaz.
sealed class PortfolioItemOutcome extends Equatable {
  final PortfolioItem item;
  const PortfolioItemOutcome({required this.item});

  PortfolioCalculation? get calculation;
  AppError? get error;

  bool get isSuccess => calculation != null;

  @override
  List<Object?> get props => [item, calculation, error];
}

final class PortfolioItemCalculatedOutcome extends PortfolioItemOutcome {
  @override
  final PortfolioCalculation calculation;

  const PortfolioItemCalculatedOutcome({
    required super.item,
    required this.calculation,
  });

  @override
  AppError? get error => null;
}

final class PortfolioItemErrorOutcome extends PortfolioItemOutcome {
  @override
  final AppError error;

  const PortfolioItemErrorOutcome({required super.item, required this.error});

  @override
  PortfolioCalculation? get calculation => null;
}
