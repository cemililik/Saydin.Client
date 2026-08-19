import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/repositories/dca_repository.dart';
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart';

class MockDcaRepository extends Mock implements DcaRepository {}

void main() {
  test(
    'calculation result receives a deterministic calculated-at snapshot',
    () async {
      final repository = MockDcaRepository();
      final source = DcaResult(
        assetSymbol: 'USDTRY',
        assetDisplayName: 'Dolar',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
        period: 'monthly',
        periodicAmount: Decimal.fromInt(100),
        totalPurchases: 2,
        totalInvestedTry: Decimal.fromInt(200),
        currentValueTry: Decimal.fromInt(220),
        profitLossTry: Decimal.fromInt(20),
        profitLossPercent: 10,
        isProfit: true,
        averageCostPerUnit: Decimal.one,
        totalUnitsAcquired: Decimal.fromInt(200),
        currentUnitPrice: Decimal.parse('1.1'),
      );
      when(
        () => repository.calculate(
          assetSymbol: 'USDTRY',
          startDate: DateTime(2024, 1, 1),
          endDate: null,
          periodicAmount: Decimal.fromInt(100),
          period: 'monthly',
          amountType: 'try',
          includeInflation: false,
        ),
      ).thenAnswer((_) async => source);
      final snapshot = DateTime(2024, 2, 2, 14, 30);
      final usecase = CalculateDca(repository, clock: () => snapshot);

      final result = await usecase(
        assetSymbol: 'USDTRY',
        startDate: DateTime(2024, 1, 1),
        periodicAmount: Decimal.fromInt(100),
        period: 'monthly',
        amountType: 'try',
      );

      expect(result.calculatedAt, snapshot);
      expect(result.currentValueTry, source.currentValueTry);
    },
  );
}
