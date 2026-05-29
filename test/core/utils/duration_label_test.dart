import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/duration_label.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

void main() {
  final l10n = AppLocalizationsTr();

  // Şablon metnini hardcode etmek yerine l10n'in kendi çıktısıyla karşılaştır:
  // hangi dal + hangi değer seçildiğini (algoritmayı) kilitler.
  group('DurationLabel.format (takvim-ayı + day-of-month ayarı)', () {
    test('format_monthBoundaryShortRange_returnsDays', () {
      // e.day(1) < start.day(31) → months 1 düşülür → 0 → gün dalı
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 31), DateTime(2020, 2, 1)),
        l10n.durationDays(1),
      );
    });

    test('format_withinSameMonth_30DaysNotMonth', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2020, 1, 31)),
        l10n.durationDays(30),
      );
    });

    test('format_fullMonths_returnsMonths', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2020, 3, 1)),
        l10n.durationMonths(2),
      );
    });

    test('format_fullYear_returnsYears', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2021, 1, 1)),
        l10n.durationYears(1),
      );
    });

    test('format_yearPlusMonths_returnsYearsMonths', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2021, 4, 1)),
        l10n.durationYearsMonths(1, 3),
      );
    });

    test('format_leapYearEndBeforeDay_returnsMonths', () {
      // months = 12; e.day(28) < start.day(29) → 11 ay
      expect(
        DurationLabel.format(
          l10n,
          DateTime(2020, 2, 29),
          DateTime(2021, 2, 28),
        ),
        l10n.durationMonths(11),
      );
    });

    test('format_nullEnd_returnsNormally', () {
      expect(
        () => DurationLabel.format(l10n, DateTime(2020, 1, 1), null),
        returnsNormally,
      );
    });
  });
}
