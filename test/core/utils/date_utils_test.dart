import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/date_utils.dart';

void main() {
  group('isSameDay (F-11-12)', () {
    test('isSameDay_sameCalendarDayDifferentTimes_returnsTrue', () {
      expect(
        isSameDay(DateTime(2020, 3, 1, 9, 30), DateTime(2020, 3, 1, 23, 59)),
        isTrue,
      );
    });

    test('isSameDay_differentDay_returnsFalse', () {
      expect(isSameDay(DateTime(2020, 3, 1), DateTime(2020, 3, 2)), isFalse);
    });

    test('isSameDay_bothNull_returnsTrue', () {
      // ör. "satış tarihi yok" eşleşmesi
      expect(isSameDay(null, null), isTrue);
    });

    test('isSameDay_oneNull_returnsFalse', () {
      expect(isSameDay(DateTime(2020, 3, 1), null), isFalse);
      expect(isSameDay(null, DateTime(2020, 3, 1)), isFalse);
    });

    test('isSameDay_leapYearFeb29_returnsTrue', () {
      expect(
        isSameDay(DateTime(2020, 2, 29, 1), DateTime(2020, 2, 29, 22)),
        isTrue,
      );
    });

    test('isSameDay_differentYearSameMonthDay_returnsFalse', () {
      expect(isSameDay(DateTime(2020, 3, 1), DateTime(2021, 3, 1)), isFalse);
    });
  });
}
