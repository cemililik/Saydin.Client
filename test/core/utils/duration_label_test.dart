import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/duration_label.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

void main() {
  final l10n = AppLocalizationsTr();

  // Şablon metnini hardcode etmek yerine l10n'in kendi çıktısıyla karşılaştır:
  // hangi dal + hangi değer seçildiğini (algoritmayı) kilitler.
  group('DurationLabel.format (takvim-ayı + day-of-month ayarı)', () {
    test('ay sınırı kısa aralık: 31 Oca → 1 Şub = 1 gün (ay şişmez)', () {
      // e.day(1) < start.day(31) → months 1 düşülür → 0 → gün dalı
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 31), DateTime(2020, 2, 1)),
        l10n.durationDays(1),
      );
    });

    test('ay-içi 30 gün → 30 gün (1 ay değil)', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2020, 1, 31)),
        l10n.durationDays(30),
      );
    });

    test('tam aylar: 1 Oca → 1 Mar = 2 ay', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2020, 3, 1)),
        l10n.durationMonths(2),
      );
    });

    test('tam yıl: 1 Oca 2020 → 1 Oca 2021 = 1 yıl', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2021, 1, 1)),
        l10n.durationYears(1),
      );
    });

    test('yıl + ay: 1 Oca 2020 → 1 Nis 2021 = 1 yıl 3 ay', () {
      expect(
        DurationLabel.format(l10n, DateTime(2020, 1, 1), DateTime(2021, 4, 1)),
        l10n.durationYearsMonths(1, 3),
      );
    });

    test('artık yıl: 29 Şub 2020 → 28 Şub 2021 = 11 ay (gün dolmadı)', () {
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

    test('end null → bugüne kadar, throw etmez', () {
      expect(
        () => DurationLabel.format(l10n, DateTime(2020, 1, 1), null),
        returnsNormally,
      );
    });
  });
}
