// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Saydın';

  @override
  String get whatIfTitle => 'Ya Alsaydım?';

  @override
  String get selectAsset => 'Varlık Seçin';

  @override
  String get buyDate => 'Alış Tarihi';

  @override
  String get sellDate => 'Satış Tarihi (opsiyonel)';

  @override
  String get amount => 'Tutar';

  @override
  String get amountHint => '10000';

  @override
  String get amountTypeTry => '₺ TL';

  @override
  String get amountTypeUnits => 'Adet';

  @override
  String get amountTypeGrams => 'Gram';

  @override
  String get calculate => 'Hesapla';

  @override
  String get calculating => 'Hesaplanıyor...';

  @override
  String get resultTitle => 'Sonuç';

  @override
  String get initialValue => 'Başlangıç Değeri';

  @override
  String get finalValue => 'Bugünkü Değer';

  @override
  String get profitLoss => 'Kar / Zarar';

  @override
  String get profitLossPercent => 'Getiri';

  @override
  String get today => 'Bugün';

  @override
  String get profit => 'Kazanç';

  @override
  String get loss => 'Kayıp';

  @override
  String get profitLabel => 'Kar';

  @override
  String get lossLabel => 'Zarar';

  @override
  String get enterAmount => 'Tutar giriniz';

  @override
  String get assetRequired => 'Varlık seçiniz';

  @override
  String get buyDateRequired => 'Alış tarihi giriniz';

  @override
  String get validAmountRequired => 'Geçerli bir tutar giriniz';

  @override
  String get errorServer => 'Sunucu hatası. Lütfen tekrar deneyin.';

  @override
  String get errorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get errorPriceNotFound => 'Bu tarih için fiyat bilgisi bulunamadı.';

  @override
  String get errorDailyLimit => 'Günlük hesaplama limitine ulaştınız.';

  @override
  String errorScenarioLimit(int limit) {
    return 'Ücretsiz planda en fazla $limit senaryo kaydedebilirsiniz.';
  }

  @override
  String get errorNoInternet => 'İnternet bağlantısı yok.';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get tryAgain => 'Tekrar Hesapla';

  @override
  String get scenariosTitle => 'Senaryolarım';

  @override
  String get scenariosEmpty => 'Henüz kaydedilen senaryo yok';

  @override
  String get scenariosEmptyHint =>
      'Hesaplama yaptıktan sonra senaryolarınızı kaydedebilirsiniz.';

  @override
  String get saveScenario => 'Kaydet';

  @override
  String get scenarioSaved => 'Senaryo kaydedildi.';

  @override
  String get scenarioDeleted => 'Senaryo silindi.';

  @override
  String get deleteScenario => 'Sil';

  @override
  String get undo => 'Geri Al';

  @override
  String get tabCalculate => 'Hesapla';

  @override
  String get tabScenarios => 'Senaryolarım';

  @override
  String get searchAsset => 'Varlık ara...';

  @override
  String get categoryCurrency => 'Döviz';

  @override
  String get categoryPreciousMetal => 'Kıymetli Maden';

  @override
  String get categoryCrypto => 'Kripto Para';

  @override
  String get categoryStock => 'Hisse Senedi';

  @override
  String get resultBuyPrice => 'Alış Fiyatı';

  @override
  String get resultSellPrice => 'Satış/Güncel Fiyatı';

  @override
  String get resultUnitsAcquired => 'Edinilen Miktar';

  @override
  String get resultDuration => 'Süre';

  @override
  String durationDays(int count) {
    return '$count gün';
  }

  @override
  String durationMonths(int count) {
    return '$count ay';
  }

  @override
  String durationYearsMonths(int years, int months) {
    return '$years yıl $months ay';
  }

  @override
  String durationYears(int count) {
    return '$count yıl';
  }

  @override
  String get dateAdjustedWarning =>
      'Seçilen tarih bu varlık için uygun değil, en yakın geçerli tarihe ayarlandı.';

  @override
  String get scenarioDuplicate => 'Bu senaryo zaten kaydedilmiş.';

  @override
  String get priceDisclaimer =>
      'Gösterilen fiyatlar yaklaşık değerlerdir. Kurum, komisyon ve kur farklılıkları nedeniyle gerçek işlem tutarları değişiklik gösterebilir.';

  @override
  String get tabCompare => 'Karşılaştır';

  @override
  String get compareTitle => 'Varlık Karşılaştırma';

  @override
  String get compareSelectAssets => 'Varlık Seçin (2-5 adet)';

  @override
  String get compareMinAssets => 'En az 2 varlık seçiniz.';

  @override
  String get compareButton => 'Karşılaştır';

  @override
  String get comparing => 'Karşılaştırılıyor...';

  @override
  String get compareResultTitle => 'Karşılaştırma Sonuçları';

  @override
  String compareRankLabel(int rank) {
    return '$rank. Sıra';
  }

  @override
  String get compareAddAsset => 'Varlık Ekle';

  @override
  String get compareAllCategories => 'Tümü';

  @override
  String get compareNoAssetsFound => 'Varlık bulunamadı';

  @override
  String get inflationAdjust => 'Enflasyona Göre Düzelt';

  @override
  String get inflationAdjustSubtitle => 'TÜFE bazlı reel getiriyi hesaplar';

  @override
  String get premiumFeature => 'Premium';

  @override
  String get realReturn => 'Reel Getiri';

  @override
  String get realProfitLoss => 'Reel Kar / Zarar';

  @override
  String get cumulativeInflation => 'Birikimli Enflasyon';

  @override
  String get inflationSectionTitle => 'Enflasyon Düzeltmesi';

  @override
  String get dateAdjustedNote => 'Tarih düzeltmesi uygulandı';

  @override
  String inflationDataAsOf(String date) {
    return 'Endeks baz tarihi: $date';
  }

  @override
  String priceDateAdjusted(String requested, String reason, String actual) {
    return 'Fiyat bulunamadı: $requested ($reason) — $actual tarihi kullanıldı.';
  }

  @override
  String get reasonWeekend => 'haftasonu';

  @override
  String get reasonHoliday => 'resmi tatil veya fiyat yok';

  @override
  String get labelBuyDate => 'Alış';

  @override
  String get labelSellDate => 'Satış';

  @override
  String get shareResult => 'Paylaş';

  @override
  String get sharePreviewTitle => 'Paylaşım Önizlemesi';

  @override
  String get sharingInProgress => 'Hazırlanıyor...';

  @override
  String get tabPortfolio => 'Portföy';

  @override
  String get portfolioTitle => 'Portföy Oluşturucu';

  @override
  String get portfolioDateSection => 'Yatırım Dönemi';

  @override
  String get portfolioAssetsSection => 'Varlıklar';

  @override
  String get portfolioAddAsset => 'Varlık Ekle';

  @override
  String get portfolioAddAssetTitle => 'Portföye Varlık Ekle';

  @override
  String get portfolioCalculate => 'Portföyü Hesapla';

  @override
  String get portfolioCalculating => 'Hesaplanıyor...';

  @override
  String get portfolioReset => 'Sıfırla';

  @override
  String get portfolioEmpty => 'Henüz varlık eklenmedi.';

  @override
  String get portfolioEmptyHint =>
      'Varlık ekleyerek portföyünüzün tarihsel getirisini hesaplayın.';

  @override
  String portfolioQuotaInfo(int count) {
    return 'Bu hesaplama $count hesaplama hakkı kullanacak.';
  }

  @override
  String get portfolioTotalInitial => 'Toplam Yatırım';

  @override
  String get portfolioTotalFinal => 'Toplam Son Değer';

  @override
  String get portfolioTotalReturn => 'Toplam Getiri';

  @override
  String get portfolioChartTitle => 'Son Değer Dağılımı';

  @override
  String get portfolioBuyDateRequired => 'Başlangıç tarihi giriniz';

  @override
  String get portfolioMinItems => 'En az 1 varlık ekleyin.';

  @override
  String portfolioHistoryLimit(int months) {
    return 'Ücretsiz planda son $months aya ait tarih seçilebilir.';
  }

  @override
  String get portfolioEditAssetTitle => 'Varlığı Düzenle';

  @override
  String get portfolioSaveAsset => 'Kaydet';

  @override
  String get portfolioInflationLabel => 'Enflasyona Göre Düzelt';

  @override
  String get portfolioRealReturn => 'Reel Toplam Getiri';

  @override
  String get portfolioRealProfitLoss => 'Reel Kar / Zarar';

  @override
  String get scenarioTypeWhatIf => 'Hesaplama';

  @override
  String get scenarioTypeComparison => 'Karşılaştırma';

  @override
  String get scenarioTypePortfolio => 'Portföy';

  @override
  String get scenarioTypeDca => 'Birikim';

  @override
  String get brandedTitlePrefix => 'al/sat ';

  @override
  String get brandedTitleSuffix => 'saydın';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSubtitle => 'Uygulamanın görünümünü seçin';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get settingsVersion => 'Versiyon';

  @override
  String get categoryFavorites => 'Favoriler';

  @override
  String favoritesMaxReached(int max) {
    return 'En fazla $max favori ekleyebilirsiniz.';
  }

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsLanguageSubtitle => 'Uygulama dilini seçin';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get shareCardInitialValue => 'Başlangıç';

  @override
  String get shareCardFinalValue => 'Son Değer';

  @override
  String get shareCardNominalReturn => 'Nominal Getiri';

  @override
  String get shareCardReturn => 'Getiri';

  @override
  String get shareCardProfit => 'kazanç';

  @override
  String get shareCardLoss => 'zarar';

  @override
  String get shareCardInflationTitle => 'Enflasyon Düzeltmesi (TÜFE)';

  @override
  String get shareCardCumulativeInflation => 'Birikimli Enflasyon';

  @override
  String get shareCardRealReturn => 'Reel Getiri';

  @override
  String get shareCardWhatIfFooter => 'Ya alsaydın?';

  @override
  String get shareCardComparisonTitle => 'Varlık Karşılaştırması';

  @override
  String get shareCardComparisonFooter => 'Hangisi daha kazandırdı?';

  @override
  String get shareCardPortfolioTitle => 'Portföy Getirisi';

  @override
  String get shareCardPortfolioFooter => 'Portföyüm ne kazandırdı?';

  @override
  String get shareCardTotalInvestment => 'Toplam Yatırım';

  @override
  String get shareCardTotalReturn => 'Toplam Getiri';

  @override
  String get shareCardNominalTotalReturn => 'Nominal Getiri';

  @override
  String shareCardAssetCount(int count) {
    return '$count varlık';
  }

  @override
  String shareTextWhatIf(
    String asset,
    String initial,
    String final_value,
    String percent,
  ) {
    return '$asset\'e $initial yatırsaydım $final_value ederdi ($percent)! 📊 #saydın';
  }

  @override
  String shareTextComparison(String winner, String percent) {
    return 'Hangi yatırım daha kazandırdı? 🏆 $winner: $percent 📊 #saydın';
  }

  @override
  String shareTextPortfolio(int count, String percent) {
    return 'Portföyüm $count varlıkla $percent getiri sağladı! 📊 #saydın';
  }

  @override
  String get shareDefaultText => 'saydın.app üzerinden hesapladım.';

  @override
  String get shareCta =>
      '\n\n📱 Saydın uygulamasını indir — App Store ve Google Play\'de \"saydın\" ara.';

  @override
  String scenarioNameComparison(int count) {
    return '$count Varlık Karşılaştırması';
  }

  @override
  String scenarioNamePortfolio(int count) {
    return 'Portföy ($count varlık)';
  }

  @override
  String get realReturnPrefix => 'Reel: ';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingGetStarted => 'Hemen Dene';

  @override
  String get onboardingPage1Title => 'Ya Alsaydım?';

  @override
  String get onboardingPage1Body =>
      'Merak ettiğin yatırımı geçmişe dönük hesapla. Dolar, altın, Bitcoin ve daha fazlası.';

  @override
  String get onboardingPage2Title => 'Karşılaştır ve Keşfet';

  @override
  String get onboardingPage2Body =>
      'Varlıkları yan yana karşılaştır, portföy oluştur. Hangisi daha kazandırdı?';

  @override
  String get onboardingPage3Title => 'Portföy Oluştur';

  @override
  String get onboardingPage3Body =>
      'Birden fazla varlıkla portföy kur, toplam getirini hesapla ve en iyi stratejiyi keşfet.';

  @override
  String get onboardingPage4Title => 'Düzenli Yatırım';

  @override
  String get onboardingPage4Body =>
      'Aylık veya haftalık düzenli alım simüle et, ortalama maliyetini ve toplam getirisini gör.';

  @override
  String get onboardingPage5Title => 'Paylaş ve Kaydet';

  @override
  String get onboardingPage5Body =>
      'Sonuçlarını arkadaşlarınla paylaş, senaryolarını kaydet ve istediğin zaman geri dön.';

  @override
  String get tabDca => 'Birikim';

  @override
  String get dcaTitle => 'Düzenli Yatırım Simülasyonu';

  @override
  String get dcaStartDate => 'Başlangıç Tarihi';

  @override
  String get dcaEndDate => 'Bitiş Tarihi (opsiyonel)';

  @override
  String get dcaStartDateRequired => 'Başlangıç tarihi giriniz';

  @override
  String get dcaPeriodWeekly => 'Haftalık';

  @override
  String get dcaPeriodMonthly => 'Aylık';

  @override
  String get dcaPeriodLabel => 'Periyot';

  @override
  String get dcaPeriodicAmountLabel => 'Periyodik Tutar';

  @override
  String get dcaPeriodicAmount => 'Periyodik Tutar';

  @override
  String get dcaCalculate => 'Simüle Et';

  @override
  String get dcaTotalInvested => 'Toplam Yatırım';

  @override
  String get dcaCurrentValue => 'Güncel Değer';

  @override
  String get dcaTotalPurchases => 'Toplam Alım';

  @override
  String get dcaAvgCost => 'Ortalama Maliyet';

  @override
  String get dcaTotalUnits => 'Toplam Adet';

  @override
  String get dcaCurrentPrice => 'Güncel Fiyat';

  @override
  String get dcaChartCost => 'Maliyet';

  @override
  String get dcaChartValue => 'Değer';

  @override
  String get shareCardDcaFooter => 'Düzenli yatırım ile birikim';

  @override
  String shareTextDca(String asset, int count, String percent) {
    return '$asset için $count alım yaptım, getiri: $percent! 📊 #saydın';
  }
}
