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

  test('portfolioQuotaInfo_enSingularAndPlural_usesCorrectCreditNoun', () {
    final en = AppLocalizationsEn();
    expect(
      en.portfolioQuotaInfo(1),
      'This calculation will use 1 calculation credit.',
    );
    expect(
      en.portfolioQuotaInfo(2),
      'This calculation will use 2 calculation credits.',
    );
  });

  test('shareTextPortfolio_enSingularAndPlural_usesCorrectAssetNoun', () {
    final en = AppLocalizationsEn();
    expect(
      en.shareTextPortfolio(1, '+10.00%'),
      'My portfolio with 1 asset returned +10.00%! 📊 #saydın',
    );
    expect(
      en.shareTextPortfolio(2, '+10.00%'),
      'My portfolio with 2 assets returned +10.00%! 📊 #saydın',
    );
  });

  test('shareTextDca_enSingularAndPlural_usesCorrectPurchaseNoun', () {
    final en = AppLocalizationsEn();
    expect(
      en.shareTextDca('Gold', 1, '+10.00%'),
      'DCA into Gold: 1 purchase, return: +10.00%! 📊 #saydın',
    );
    expect(
      en.shareTextDca('Gold', 2, '+10.00%'),
      'DCA into Gold: 2 purchases, return: +10.00%! 📊 #saydın',
    );
  });

  test('portfolioAndDcaPlurals_trCounts_preserveSuffixlessNouns', () {
    final tr = AppLocalizationsTr();
    expect(
      tr.portfolioQuotaInfo(1),
      'Bu hesaplama 1 hesaplama hakkı kullanacak.',
    );
    expect(
      tr.portfolioQuotaInfo(2),
      'Bu hesaplama 2 hesaplama hakkı kullanacak.',
    );
    expect(
      tr.shareTextPortfolio(2, '+%10,00'),
      'Portföyüm 2 varlıkla +%10,00 getiri sağladı! 📊 #saydın',
    );
    expect(
      tr.shareTextDca('Altın', 2, '+%10,00'),
      'Altın için 2 alım yaptım, getiri: +%10,00! 📊 #saydın',
    );
  });
}
