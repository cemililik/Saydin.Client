import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

/// Tüm portföy kalemlerini paralel hesaplar, toplam sonucu döner.
///
/// Per-item try/catch ile fail-fast davranışı önlenir: bir kalem (örn
/// `BIST/THYAO` backend'de geçici 503) çökerse, geri kalan kalemler
/// hesaplanmaya devam eder ve UI partial result gösterir. Tüm kalemler
/// çökerse [PortfolioCalculationFailure] fırlatılır.
class CalculatePortfolio {
  final WhatIfRepository _repository;

  const CalculatePortfolio(this._repository);

  Future<PortfolioResult> call({
    required List<PortfolioItem> items,
    required DateTime buyDate,
    DateTime? sellDate,
    bool includeInflation = false,
  }) async {
    assert(items.isNotEmpty, 'Portföyde en az 1 kalem olmalı');

    final outcomes = await Future.wait(
      items.map((item) async {
        try {
          final r = await _repository.calculate(
            assetSymbol: item.assetSymbol,
            buyDate: buyDate,
            sellDate: sellDate,
            amount: item.amount,
            amountType: item.amountType,
            includeInflation: includeInflation,
          );
          return _ItemOutcome(item: item, result: r);
        } catch (_) {
          // İlk hatada `rethrow` etsek `Future.wait` tüm kalemleri reddederdi.
          // Per-item ayrı outcome ile partial-success akışı korunur. Hata
          // detayı caller'a BLoC level'da Sentry'ye gider (use-case katmanı
          // bağımlılık yaymaz).
          return _ItemOutcome(item: item);
        }
      }),
    );

    final successful = outcomes.where((o) => o.result != null).toList();
    final failedItems = outcomes
        .where((o) => o.result == null)
        .map((o) => o.item)
        .toList(growable: false);

    if (successful.isEmpty) {
      throw const PortfolioCalculationFailure(
        'Portföydeki hiçbir kalem hesaplanamadı.',
      );
    }

    final results = successful.map((o) => o.result!).toList(growable: false);
    final keptItems = successful.map((o) => o.item).toList(growable: false);

    final totalInitial = results.fold(0.0, (sum, r) => sum + r.initialValueTry);
    final totalFinal = results.fold(0.0, (sum, r) => sum + r.finalValueTry);
    final totalPnL = totalFinal - totalInitial;
    final totalPct = totalInitial > 0 ? (totalPnL / totalInitial) * 100 : 0.0;

    final itemResults = List.generate(keptItems.length, (i) {
      final share = totalFinal > 0
          ? results[i].finalValueTry / totalFinal * 100
          : 0.0;
      return PortfolioItemResult(
        item: keptItems[i],
        result: results[i],
        sharePercent: share,
      );
    });

    // Enflasyon aggregasyonu — sadece tüm kalemlerde inflation verisi varsa
    double? totalRealPnL;
    double? totalRealPct;
    double? totalInflation;

    if (includeInflation &&
        results.every((r) => r.realProfitLossPercent != null)) {
      // Her kalemin reel son değeri: initialValue * (1 + realPct/100)
      double totalRealFinal = 0;
      for (final r in results) {
        totalRealFinal +=
            r.initialValueTry * (1 + r.realProfitLossPercent! / 100);
      }
      totalRealPnL = totalRealFinal - totalInitial;
      totalRealPct = totalInitial > 0
          ? (totalRealPnL / totalInitial) * 100
          : 0.0;

      // Ağırlıklı ortalama birikimli enflasyon (başlangıç değeri ağırlıklı)
      if (results.every((r) => r.cumulativeInflationPercent != null) &&
          totalInitial > 0) {
        double weightedInfl = 0;
        for (final r in results) {
          weightedInfl +=
              r.cumulativeInflationPercent! *
              (r.initialValueTry / totalInitial);
        }
        totalInflation = weightedInfl;
      }
    }

    return PortfolioResult(
      items: itemResults,
      failedItems: failedItems,
      totalInitialValueTry: totalInitial,
      totalFinalValueTry: totalFinal,
      totalProfitLossTry: totalPnL,
      totalProfitLossPercent: totalPct,
      isProfit: totalPnL >= 0,
      totalRealProfitLossTry: totalRealPnL,
      totalRealProfitLossPercent: totalRealPct,
      totalCumulativeInflationPercent: totalInflation,
    );
  }
}

/// Tüm kalemler hesaplama sırasında çöktüğünde fırlatılır. BLoC bunu
/// `PortfolioFailure` state'ine map'ler.
class PortfolioCalculationFailure implements Exception {
  final String message;
  const PortfolioCalculationFailure(this.message);

  @override
  String toString() => 'PortfolioCalculationFailure: $message';
}

class _ItemOutcome {
  final PortfolioItem item;
  final WhatIfResult? result;

  const _ItemOutcome({required this.item, this.result});
}
