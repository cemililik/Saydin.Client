import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

void main() {
  Asset asset(String symbol, DateTime first, DateTime last) => Asset(
    symbol: symbol,
    displayName: symbol,
    category: 'test',
    firstDate: first,
    lastDate: last,
  );

  test('comparisonDateRange örtüşmesiz varlıkları açıkça işaretler', () {
    final range = comparisonDateRange(
      assets: [
        asset('A', DateTime(2020), DateTime(2021)),
        asset('B', DateTime(2022), DateTime(2023)),
      ],
      selectedSymbols: const ['A', 'B'],
      priceHistoryMonths: 0,
    );

    expect(range.hasOverlap, isFalse);
    expect(range.firstDate, isNull);
    expect(range.lastDate, isNull);
  });

  test('comparisonDateRange ortak kesişimi döndürür', () {
    final range = comparisonDateRange(
      assets: [
        asset('A', DateTime(2020), DateTime(2023)),
        asset('B', DateTime(2021), DateTime(2024)),
      ],
      selectedSymbols: const ['A', 'B'],
      priceHistoryMonths: 0,
    );

    expect(range.hasOverlap, isTrue);
    expect(range.firstDate, DateTime(2021));
    expect(range.lastDate, DateTime(2023));
  });

  group('subtractCalendarMonthsClamped', () {
    test('31 Mart eksi 1 ay Şubat sonuna clamp edilir', () {
      expect(
        subtractCalendarMonthsClamped(DateTime(2023, 3, 31), 1),
        DateTime(2023, 2, 28),
      );
    });

    test('artık yılda Şubat 29 korunur', () {
      expect(
        subtractCalendarMonthsClamped(DateTime(2024, 3, 31), 1),
        DateTime(2024, 2, 29),
      );
    });

    test('yıl geçişi ve sıfır ay deterministiktir', () {
      expect(
        subtractCalendarMonthsClamped(DateTime(2024, 1, 31), 2),
        DateTime(2023, 11, 30),
      );
      expect(
        subtractCalendarMonthsClamped(DateTime(2024, 1, 31, 23), 0),
        DateTime(2024, 1, 31),
      );
    });

    test('negatif ay reddedilir', () {
      expect(
        () => subtractCalendarMonthsClamped(DateTime(2024), -1),
        throwsArgumentError,
      );
    });
  });

  test('financial date range aynı gün geçerli, ters sıra geçersizdir', () {
    expect(
      isValidFinancialDateRange(DateTime(2024, 1, 1), DateTime(2024, 1, 1)),
      isTrue,
    );
    expect(
      isValidFinancialDateRange(DateTime(2024, 1, 2), DateTime(2024, 1, 1)),
      isFalse,
    );
  });
}
