import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';

void main() {
  group('FinancialAmountValidator', () {
    test('TRY iki, gram dört, unit sekiz ondalığı kabul eder', () {
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.parse('0.01'),
          amountType: 'try',
        ),
        isTrue,
      );
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.parse('0.0001'),
          amountType: 'grams',
        ),
        isTrue,
      );
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.parse('0.00000001'),
          amountType: 'units',
        ),
        isTrue,
      );
    });

    test('scale, maksimum ve amount-type uyumsuzluğu reddedilir', () {
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.parse('1.001'),
          amountType: 'try',
        ),
        isFalse,
      );
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.parse('1000000000.01'),
          amountType: 'try',
        ),
        isFalse,
      );
      expect(
        FinancialAmountValidator.isValid(
          value: Decimal.one,
          amountType: 'grams',
          allowedAmountTypes: const ['try', 'units'],
        ),
        isFalse,
      );
    });
  });
}
