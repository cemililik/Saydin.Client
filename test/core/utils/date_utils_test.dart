import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/date_utils.dart';

void main() {
  group('isSameDay (F-11-12)', () {
    test('aynı gün, farklı saat → true', () {
      expect(
        isSameDay(DateTime(2020, 3, 1, 9, 30), DateTime(2020, 3, 1, 23, 59)),
        isTrue,
      );
    });

    test('farklı gün → false', () {
      expect(isSameDay(DateTime(2020, 3, 1), DateTime(2020, 3, 2)), isFalse);
    });

    test('ikisi de null → true (ör. "satış tarihi yok" eşleşmesi)', () {
      expect(isSameDay(null, null), isTrue);
    });

    test('yalnızca biri null → false', () {
      expect(isSameDay(DateTime(2020, 3, 1), null), isFalse);
      expect(isSameDay(null, DateTime(2020, 3, 1)), isFalse);
    });

    test('artık yıl 29 Şubat tutarlı', () {
      expect(
        isSameDay(DateTime(2020, 2, 29, 1), DateTime(2020, 2, 29, 22)),
        isTrue,
      );
    });

    test('yıl farkı (aynı ay/gün) → false', () {
      expect(isSameDay(DateTime(2020, 3, 1), DateTime(2021, 3, 1)), isFalse);
    });
  });
}
