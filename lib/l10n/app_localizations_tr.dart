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
  String get tabCalculate => 'Hesapla';

  @override
  String get tabScenarios => 'Senaryolarım';
}
