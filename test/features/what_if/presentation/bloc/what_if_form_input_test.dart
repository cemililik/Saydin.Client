import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';

void main() {
  group('WhatIfFormInput.copyWith', () {
    test('dateAdjusted varsayılan olarak false\'a sıfırlanır', () {
      const input = WhatIfFormInput(
        selectedSymbol: 'USDTRY',
        dateAdjusted: true,
      );

      final updated = input.copyWith(amountType: 'units');

      expect(updated.dateAdjusted, false);
    });

    test('dateAdjusted açıkça true olarak set edilebilir', () {
      const input = WhatIfFormInput(selectedSymbol: 'USDTRY');

      final updated = input.copyWith(dateAdjusted: true);

      expect(updated.dateAdjusted, true);
    });

    test('dateAdjusted sıfırlanırken diğer alanlar korunur', () {
      final buyDate = DateTime(2020, 1, 1);
      final input = WhatIfFormInput(
        selectedSymbol: 'USDTRY',
        buyDate: buyDate,
        amountType: 'units',
        amount: 10000,
        dateAdjusted: true,
      );

      final updated = input.copyWith();

      expect(updated.selectedSymbol, 'USDTRY');
      expect(updated.buyDate, buyDate);
      expect(updated.amountType, 'units');
      expect(updated.amount, 10000);
      expect(updated.dateAdjusted, false);
    });

    test('selectedSymbol null olarak set edilebilir', () {
      const input = WhatIfFormInput(selectedSymbol: 'USDTRY');

      final updated = input.copyWith(selectedSymbol: null);

      expect(updated.selectedSymbol, isNull);
    });

    test('buyDate null olarak set edilebilir', () {
      final input = WhatIfFormInput(buyDate: DateTime(2020, 1, 1));

      final updated = input.copyWith(buyDate: null);

      expect(updated.buyDate, isNull);
    });

    test('eşitlik: aynı değerler eşit kabul edilir', () {
      const a = WhatIfFormInput(selectedSymbol: 'BTC', amountType: 'try');
      const b = WhatIfFormInput(selectedSymbol: 'BTC', amountType: 'try');

      expect(a, equals(b));
    });

    test('eşitlik: dateAdjusted farklıysa eşit değil', () {
      const a = WhatIfFormInput(selectedSymbol: 'BTC', dateAdjusted: false);
      const b = WhatIfFormInput(selectedSymbol: 'BTC', dateAdjusted: true);

      expect(a, isNot(equals(b)));
    });
  });
}
