import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

/// [PortfolioRepository] implementasyonu.
///
/// Portföyün ayrı bir backend endpoint'i yoktur — her kalem tekil bir
/// "ya alsaydım" hesabıdır. Bu yüzden hesaplamayı `WhatIfRepository`'ye
/// **delege eder** (kalıtım değil kompozisyon). `WhatIfResult` (What-If domain
/// entity'si) yalnızca **bu data katmanında** görülür ve portföye ait
/// [PortfolioCalculation]'a map'lenir; böylece portföy domain'i What-If'ten
/// bağımsız kalır (F-09-01 + F-09-19).
///
/// > Not: Backend ileride bir batch `/v1/portfolio/calculate` endpoint'i
/// > eklerse [calculateItems] sözleşmesi sabit kalır; sadece bu impl,
/// > delegasyon yerine doğrudan Dio çağrısına geçer.
class PortfolioRepositoryImpl implements PortfolioRepository {
  final WhatIfRepository _whatIfRepository;

  const PortfolioRepositoryImpl(this._whatIfRepository);

  @override
  Future<List<PortfolioItemOutcome>> calculateItems({
    required List<PortfolioItem> items,
    required DateTime buyDate,
    DateTime? sellDate,
    bool includeInflation = false,
  }) {
    return Future.wait(
      items.map((item) async {
        try {
          final result = await _whatIfRepository.calculate(
            assetSymbol: item.assetSymbol,
            buyDate: buyDate,
            sellDate: sellDate,
            amount: item.amount,
            amountType: item.amountType,
            includeInflation: includeInflation,
          );
          return PortfolioItemOutcome(
            item: item,
            calculation: _toCalculation(result),
          );
        } catch (_) {
          // Per-item izolasyon: bir kalem (örn. backend 503) çökerse `rethrow`
          // tüm `Future.wait`'i reddederdi. Hatalı kalemi `calculation: null`
          // ile işaretle; use case partial-success akışını sürdürür. Hata
          // detayı use case / BLoC katmanında ele alınır (data katmanı bağımlılık
          // yaymaz).
          return PortfolioItemOutcome(item: item);
        }
      }),
    );
  }

  /// What-If domain entity'sini portföye ait entity'ye indirger (yalnızca
  /// portföyün kullandığı alanlar). Bu eşleme data katmanının sınırıdır —
  /// `WhatIfResult` import'u burada izole edilir.
  PortfolioCalculation _toCalculation(WhatIfResult r) => PortfolioCalculation(
    initialValueTry: r.initialValueTry,
    finalValueTry: r.finalValueTry,
    profitLossPercent: r.profitLossPercent,
    isProfit: r.isProfit,
    cumulativeInflationPercent: r.cumulativeInflationPercent,
    realProfitLossPercent: r.realProfitLossPercent,
  );
}
