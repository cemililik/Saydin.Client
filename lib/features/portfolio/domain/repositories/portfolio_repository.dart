import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';

/// Portföy kalemlerinin fiyat/hesaplama verisini sağlayan repository soyutlaması.
///
/// Önceden portföy [CalculatePortfolio] use case'i doğrudan `WhatIfRepository`'ye
/// bağımlıydı; portföy feature'ının kendi `data/` katmanı yoktu (F-09-01: Clean
/// Architecture sözleşme ihlali). Bu arayüz portföye kendi data sınırını verir;
/// implementasyon (`PortfolioRepositoryImpl`) hesaplamayı What-If repository'sine
/// **delege eder** (kompozisyon) ve sonucu portföye ait entity'ye map'ler.
abstract class PortfolioRepository {
  /// Her kalemi paralel hesaplar ve kalem-başına sonuç döner.
  ///
  /// Per-item izolasyon: bir kalem çökerse typed
  /// [PortfolioItemErrorOutcome] döner; diğer kalemler etkilenmez. Böylece use
  /// case partial-success kapsamını ve nedenini gösterebilir.
  Future<List<PortfolioItemOutcome>> calculateItems({
    required List<PortfolioItem> items,
    required DateTime buyDate,
    DateTime? sellDate,
    bool includeInflation = false,
  });
}
