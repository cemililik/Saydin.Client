import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

void main() {
  test(
    'bütün açık uçlu comparison kalemleri aynı sonuç snapshotını taşır',
    () async {
      final calculatedAt = DateTime(2025, 8, 12, 23, 59);
      final result =
          await CompareWhatIf(
            _FakeComparisonRepository(),
            clock: () => calculatedAt,
          ).call(
            assetSymbols: const ['AAA', 'BBB'],
            buyDate: DateTime(2020),
            amount: Decimal.fromInt(100),
            amountType: 'try',
          );

      expect(
        result.results.map((item) => item.calculation.calculatedAt),
        everyElement(calculatedAt),
      );
      expect(
        result.results.map((item) => item.calculation.effectiveSellDate),
        everyElement(DateTime(2025, 8, 12)),
      );
    },
  );
}

class _FakeComparisonRepository implements ComparisonRepository {
  @override
  Future<CompareResult> compare({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    bool includeInflation = false,
  }) async => CompareResult(
    results: List.generate(
      assetSymbols.length,
      (index) => CompareResultItem(
        rank: index + 1,
        calculation: WhatIfResult(
          assetSymbol: assetSymbols[index],
          assetDisplayName: assetSymbols[index],
          buyDate: buyDate,
          sellDate: sellDate,
          buyPrice: Decimal.one,
          sellPrice: Decimal.fromInt(2),
          unitsAcquired: Decimal.fromInt(100),
          initialValueTry: amount,
          finalValueTry: Decimal.fromInt(200),
          profitLossTry: Decimal.fromInt(100),
          profitLossPercent: 100,
          isProfit: true,
        ),
      ),
    ),
  );
}
