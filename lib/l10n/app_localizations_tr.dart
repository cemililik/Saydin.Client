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
}
