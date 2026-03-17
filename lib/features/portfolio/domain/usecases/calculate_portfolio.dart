import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

/// Tüm portföy kalemlerini paralel hesaplar, toplam sonucu döner.
class CalculatePortfolio {
  final WhatIfRepository _repository;

  const CalculatePortfolio(this._repository);

  Future<PortfolioResult> call({
    required List<PortfolioItem> items,
    required DateTime buyDate,
    DateTime? sellDate,
  }) async {
    assert(items.isNotEmpty, 'Portföyde en az 1 kalem olmalı');

    final results = await Future.wait(
      items.map(
        (item) => _repository.calculate(
          assetSymbol: item.assetSymbol,
          buyDate: buyDate,
          sellDate: sellDate,
          amount: item.amount,
          amountType: item.amountType,
        ),
      ),
    );

    final totalInitial = results.fold(0.0, (sum, r) => sum + r.initialValueTry);
    final totalFinal = results.fold(0.0, (sum, r) => sum + r.finalValueTry);
    final totalPnL = totalFinal - totalInitial;
    final totalPct = totalInitial > 0 ? (totalPnL / totalInitial) * 100 : 0.0;

    final itemResults = List.generate(items.length, (i) {
      final share = totalFinal > 0
          ? results[i].finalValueTry / totalFinal * 100
          : 0.0;
      return PortfolioItemResult(
        item: items[i],
        result: results[i],
        sharePercent: share,
      );
    });

    return PortfolioResult(
      items: itemResults,
      totalInitialValueTry: totalInitial,
      totalFinalValueTry: totalFinal,
      totalProfitLossTry: totalPnL,
      totalProfitLossPercent: totalPct,
      isProfit: totalPnL >= 0,
    );
  }
}
