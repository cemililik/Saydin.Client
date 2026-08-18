import 'package:decimal/decimal.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/domain/repositories/portfolio_repository.dart';

/// Portföy kalemlerinin kalem-başına sonucunu [PortfolioRepository]'den alır
/// ve toplam sonucu (Decimal aritmetiğiyle) hesaplar.
///
/// Per-item hesaplama + hata izolasyonu **repository katmanına** taşındı
/// (F-09-01): bir kalem çökerse repo onu `calculation: null` ile döner, use
/// case bu kalemleri `failedItems`'a düşürüp partial result üretir. Tüm
/// kalemler çökerse [PortfolioCalculationFailure] fırlatılır.
///
/// **Decimal aritmetiği:** Para alanları (initial, final, P/L) `Decimal`
/// üzerinden toplanır — IEEE-754 toplama hatası (örn. `0.1 + 0.2`) elimine.
/// Yüzde alanları `double` (display-only, aggregasyon precision'a hassas değil).
class CalculatePortfolio {
  final PortfolioRepository _repository;
  final DateTime Function() _clock;

  CalculatePortfolio(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<PortfolioResult> call({
    required List<PortfolioItem> items,
    required DateTime buyDate,
    DateTime? sellDate,
    bool includeInflation = false,
  }) async {
    assert(items.isNotEmpty, 'Portföyde en az 1 kalem olmalı');

    final outcomes = await _repository.calculateItems(
      items: items,
      buyDate: buyDate,
      sellDate: sellDate,
      includeInflation: includeInflation,
    );

    final successful = outcomes.where((o) => o.isSuccess).toList();
    final failures = outcomes
        .where((o) => !o.isSuccess)
        .map((o) => PortfolioItemFailure(item: o.item, error: o.error!))
        .toList(growable: false);

    if (successful.isEmpty) {
      throw _aggregateFailure(failures);
    }

    final results = successful
        // `!` güvenli: PortfolioItemOutcome.isSuccess => calculation != null,
        // successful zaten isSuccess ile filtrelendi.
        .map((o) => o.calculation!)
        .toList(growable: false);
    final keptItems = successful.map((o) => o.item).toList(growable: false);

    final totalInitial = results.fold<Decimal>(
      Decimal.zero,
      (sum, r) => sum + r.initialValueTry,
    );
    final totalFinal = results.fold<Decimal>(
      Decimal.zero,
      (sum, r) => sum + r.finalValueTry,
    );
    final totalPnL = totalFinal - totalInitial;
    // Yüzde display-only, double yeterli; Decimal / Decimal Rational
    // dönüyor — `.toDouble()` ile floor cast.
    final totalPct = totalInitial > Decimal.zero
        ? (totalPnL / totalInitial).toDouble() * 100
        : 0.0;

    final itemResults = List.generate(keptItems.length, (i) {
      final share = totalFinal > Decimal.zero
          ? (results[i].finalValueTry / totalFinal).toDouble() * 100
          : 0.0;
      return PortfolioItemResult(
        item: keptItems[i],
        calculation: results[i],
        sharePercent: share,
      );
    });

    // Enflasyon aggregasyonu — sadece tüm kalemlerde inflation verisi varsa
    Decimal? totalRealPnL;
    double? totalRealPct;
    double? totalInflation;

    if (includeInflation &&
        results.every((r) => r.realProfitLossPercent != null)) {
      // Her kalemin reel son değeri: initialValue * (1 + realPct/100)
      //
      // Önceki implementasyon: `Decimal.parse((1 + realPct / 100).toString())`
      // double aritmetiğine baş vuruyordu → 7.7% gibi düz değerlerde sorun
      // yok ama 33.333% (1/3) gibi case'lerde double precision (17. ondalık)
      // kaybı Decimal'a sızdırıyordu. Şimdi (100 + realPct) / 100 Decimal
      // aritmetiğinde hesaplanır; intermediate double yok.
      final hundred = Decimal.fromInt(100);
      var totalRealFinal = Decimal.zero;
      for (final r in results) {
        final rateDecimal = Decimal.parse(r.realProfitLossPercent!.toString());
        // (100 + rate) / 100 → Rational; Decimal'a düşürmek için
        // `toDecimal(scaleOnInfinitePrecision: ...)` kullan. realPct
        // typically ≤4 ondalık olduğu için scale=10 fazlasıyla yeter.
        final realFactor = ((hundred + rateDecimal) / hundred).toDecimal(
          scaleOnInfinitePrecision: 10,
        );
        totalRealFinal += r.initialValueTry * realFactor;
      }
      totalRealPnL = totalRealFinal - totalInitial;
      totalRealPct = totalInitial > Decimal.zero
          ? (totalRealPnL / totalInitial).toDouble() * 100
          : 0.0;

      // Ağırlıklı ortalama birikimli enflasyon (başlangıç değeri ağırlıklı)
      if (results.every((r) => r.cumulativeInflationPercent != null) &&
          totalInitial > Decimal.zero) {
        double weightedInfl = 0;
        final totalInitialDouble = totalInitial.toDouble();
        for (final r in results) {
          weightedInfl +=
              r.cumulativeInflationPercent! *
              (r.initialValueTry.toDouble() / totalInitialDouble);
        }
        totalInflation = weightedInfl;
      }
    }

    return PortfolioResult(
      items: itemResults,
      failures: failures,
      totalInitialValueTry: totalInitial,
      totalFinalValueTry: totalFinal,
      totalProfitLossTry: totalPnL,
      totalProfitLossPercent: totalPct,
      isProfit: totalPnL >= Decimal.zero,
      effectiveSellDate: sellDate ?? _dateOnly(_clock()),
      totalRealProfitLossTry: totalRealPnL,
      totalRealProfitLossPercent: totalRealPct,
      totalCumulativeInflationPercent: totalInflation,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  AppError _aggregateFailure(List<PortfolioItemFailure> failures) {
    final errors = failures.map((failure) => failure.error).toList();
    T? first<T extends AppError>() => errors.whereType<T>().firstOrNull;

    // Kullanıcı-aksiyonlu hata önceliği: kota/plan > bağlantı > sunucu >
    // beklenmedik. Aynı batch'teki typed neden generic exception'a düşmez.
    return first<DailyLimitError>() ??
        first<FeatureDisabledError>() ??
        first<NoInternetError>() ??
        first<PriceNotFoundError>() ??
        first<AssetNotFoundError>() ??
        first<ForbiddenError>() ??
        first<NotFoundError>() ??
        first<MalformedResponseError>() ??
        first<ServerError>() ??
        first<UnknownError>() ??
        const UnknownError();
  }
}
