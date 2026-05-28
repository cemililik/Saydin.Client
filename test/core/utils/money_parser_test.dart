import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/money_parser.dart';

void main() {
  group('MoneyParser.tryDecimal', () {
    test('null girdi null döner', () {
      expect(MoneyParser.tryDecimal(null), isNull);
    });

    test('int kabul edilir', () {
      expect(MoneyParser.tryDecimal(42), Decimal.fromInt(42));
    });

    test('double kabul edilir (precision korunur)', () {
      expect(MoneyParser.tryDecimal(0.1), Decimal.parse('0.1'));
      expect(MoneyParser.tryDecimal(47010.34), Decimal.parse('47010.34'));
    });

    test('String kabul edilir', () {
      expect(MoneyParser.tryDecimal('47010.34'), Decimal.parse('47010.34'));
      expect(MoneyParser.tryDecimal('  100  '), Decimal.fromInt(100));
    });

    test('Decimal kabul edilir (pass-through)', () {
      final d = Decimal.parse('1.23');
      expect(MoneyParser.tryDecimal(d), d);
    });

    test('boş string null döner', () {
      expect(MoneyParser.tryDecimal(''), isNull);
      expect(MoneyParser.tryDecimal('   '), isNull);
    });

    test('NaN ve Infinity null döner', () {
      expect(MoneyParser.tryDecimal(double.nan), isNull);
      expect(MoneyParser.tryDecimal(double.infinity), isNull);
      expect(MoneyParser.tryDecimal(double.negativeInfinity), isNull);
    });

    test('invalid string null döner', () {
      expect(MoneyParser.tryDecimal('abc'), isNull);
      expect(MoneyParser.tryDecimal('1.2.3'), isNull);
    });

    test('bool/Map gibi tipler null döner', () {
      expect(MoneyParser.tryDecimal(true), isNull);
      expect(MoneyParser.tryDecimal(<String, dynamic>{}), isNull);
    });
  });

  group('MoneyParser.requireDecimal', () {
    test('geçerli değer döner', () {
      expect(
        MoneyParser.requireDecimal('100.50', 'amount'),
        Decimal.parse('100.50'),
      );
    });

    test('null FormatException fırlatır', () {
      expect(
        () => MoneyParser.requireDecimal(null, 'price'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('price'),
          ),
        ),
      );
    });

    test('invalid string FormatException fırlatır', () {
      expect(
        () => MoneyParser.requireDecimal('abc', 'amount'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MoneyParser.toJsonString', () {
    test('Decimal → String round-trip', () {
      expect(MoneyParser.toJsonString(Decimal.parse('47010.34')), '47010.34');
      expect(MoneyParser.toJsonString(Decimal.fromInt(100)), '100');
    });
  });

  group('Decimal precision invariants', () {
    test('0.1 + 0.2 == 0.3 (Decimal\'da exact)', () {
      final result = Decimal.parse('0.1') + Decimal.parse('0.2');
      expect(result, Decimal.parse('0.3'));
    });

    test('finansal toplama: 47010.34 + 1234.56 doğru', () {
      final a = Decimal.parse('47010.34');
      final b = Decimal.parse('1234.56');
      expect(a + b, Decimal.parse('48244.90'));
    });
  });
}
