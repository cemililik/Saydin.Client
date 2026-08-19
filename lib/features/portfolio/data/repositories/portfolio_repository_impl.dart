import 'dart:async';

import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/error/response_body_validator.dart';
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
  final ErrorReporter _reporter;

  const PortfolioRepositoryImpl(
    this._whatIfRepository, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter;

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
          return PortfolioItemCalculatedOutcome(
            item: item,
            calculation: _toCalculation(result),
          );
        } catch (e, st) {
          // Per-item izolasyon: bir kalem (örn. backend 503) çökerse `rethrow`
          // tüm `Future.wait`'i reddederdi. Hatalı kalemi `calculation: null`
          // ile işaretle; use case partial-success akışını sürdürür. Hata
          // detayı use case / BLoC katmanında ele alınır (data katmanı bağımlılık
          // yaymaz).
          //
          // AppError (beklenen ağ hatası, örn. ServerError) sessizce işaretlenir.
          // Ama beklenmedik programlama hatası (TypeError vb.) telemetrisiz
          // "veri yok" gibi maskelenmesin → fire-and-forget raporla (L-2).
          // Raporu await ETME: `Future.wait` paralelliğini bloklamaz.
          if (e is! AppError) {
            unawaited(
              _reporter.report(e, st, context: 'portfolio_item_calculate'),
            );
          }
          return PortfolioItemErrorOutcome(
            item: item,
            error: e is AppError ? e : UnknownError(cause: e),
          );
        }
      }),
    );
  }

  /// What-If domain entity'sini portföye ait entity'ye indirger (yalnızca
  /// portföyün kullandığı alanlar). Bu eşleme data katmanının sınırıdır —
  /// `WhatIfResult` import'u burada izole edilir.
  PortfolioCalculation _toCalculation(WhatIfResult r) =>
      ResponseBodyValidator.parse(
        () => PortfolioCalculation(
          initialValueTry: r.initialValueTry,
          finalValueTry: r.finalValueTry,
          profitLossPercent: ResponseBodyValidator.requireFiniteDouble(
            r.profitLossPercent,
            'profitLossPercent',
          ),
          isProfit: r.isProfit,
          cumulativeInflationPercent:
              ResponseBodyValidator.optionalFiniteDouble(
                r.cumulativeInflationPercent,
                'cumulativeInflationPercent',
              ),
          realProfitLossPercent: ResponseBodyValidator.optionalFiniteDouble(
            r.realProfitLossPercent,
            'realProfitLossPercent',
          ),
          requestedBuyDate: r.buyDate,
          effectiveBuyDate: r.actualBuyDate ?? r.buyDate,
          requestedSellDate: r.sellDate,
          effectiveSellDate: _effectiveSellDate(r),
          calculatedAt: r.calculatedAt,
          inflationDataAsOf: r.inflationDataAsOf,
        ),
      );

  static DateTime _effectiveSellDate(WhatIfResult result) {
    if (result.actualSellDate != null) return result.actualSellDate!;
    if (result.sellDate != null) return result.sellDate!;
    if (result.priceHistory.isNotEmpty) {
      return result.priceHistory
          .map((point) => point.date)
          .reduce((left, right) => right.isAfter(left) ? right : left);
    }
    if (result.calculatedAt != null) {
      final value = result.calculatedAt!;
      return DateTime(value.year, value.month, value.day);
    }
    return result.buyDate;
  }
}
