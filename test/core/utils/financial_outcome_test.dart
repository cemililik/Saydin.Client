import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/core/utils/profit_direction_validator.dart';

void main() {
  group('FinancialOutcome', () {
    test('exact Decimal işaretini profit neutral loss olarak ayırır', () {
      expect(
        FinancialOutcome.fromAmount(Decimal.parse('0.00000001')),
        FinancialOutcome.profit,
      );
      expect(
        FinancialOutcome.fromAmount(Decimal.zero),
        FinancialOutcome.neutral,
      );
      expect(
        FinancialOutcome.fromAmount(Decimal.parse('-0.00000001')),
        FinancialOutcome.loss,
      );
    });

    test('yüzde sıfırını neutral sayar', () {
      expect(FinancialOutcome.fromPercent(-0.0), FinancialOutcome.neutral);
      expect(FinancialOutcome.fromPercent(0), FinancialOutcome.neutral);
    });
  });

  group('ProfitDirectionValidator legacy boolean', () {
    test('sıfırda true veya false backend değeri kabul edilir', () {
      for (final raw in [true, false, null]) {
        expect(
          ProfitDirectionValidator.derive(
            rawIsProfit: raw,
            profitLossTry: Decimal.zero,
            context: 'test',
          ),
          isFalse,
        );
      }
    });

    test('sıfır dışında çelişkili boolean reddedilir', () {
      expect(
        () => ProfitDirectionValidator.derive(
          rawIsProfit: false,
          profitLossTry: Decimal.one,
          context: 'test',
        ),
        throwsFormatException,
      );
    });
  });
}
