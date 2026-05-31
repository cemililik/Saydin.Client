import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/l10n/app_localizations_en.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

/// `durationYearsMonths` ICU çoğul çekimi regresyonu (F-... review bulgusu).
/// EN'de years/months için tekil/çoğul ayrımı olmalı; TR'de çoğul eki yoktur.
void main() {
  test('durationYearsMonths EN: tekil/çoğul doğru', () {
    final en = AppLocalizationsEn();
    expect(en.durationYearsMonths(1, 1), '1 year 1 month');
    expect(en.durationYearsMonths(1, 3), '1 year 3 months');
    expect(en.durationYearsMonths(2, 1), '2 years 1 month');
    expect(en.durationYearsMonths(3, 5), '3 years 5 months');
  });

  test('durationYearsMonths TR: çoğul eki yok, tutarlı', () {
    final tr = AppLocalizationsTr();
    expect(tr.durationYearsMonths(1, 1), '1 yıl 1 ay');
    expect(tr.durationYearsMonths(2, 3), '2 yıl 3 ay');
  });
}
