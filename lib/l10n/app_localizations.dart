import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saydın'**
  String get appTitle;

  /// No description provided for @whatIfTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ya Alsaydım?'**
  String get whatIfTitle;

  /// No description provided for @selectAsset.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Seçin'**
  String get selectAsset;

  /// No description provided for @buyDate.
  ///
  /// In tr, this message translates to:
  /// **'Alış Tarihi'**
  String get buyDate;

  /// No description provided for @sellDate.
  ///
  /// In tr, this message translates to:
  /// **'Satış Tarihi (opsiyonel)'**
  String get sellDate;

  /// No description provided for @amount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get amount;

  /// No description provided for @amountHint.
  ///
  /// In tr, this message translates to:
  /// **'10000'**
  String get amountHint;

  /// No description provided for @amountTypeTry.
  ///
  /// In tr, this message translates to:
  /// **'₺ TL'**
  String get amountTypeTry;

  /// No description provided for @amountTypeUnits.
  ///
  /// In tr, this message translates to:
  /// **'Adet'**
  String get amountTypeUnits;

  /// No description provided for @amountTypeGrams.
  ///
  /// In tr, this message translates to:
  /// **'Gram'**
  String get amountTypeGrams;

  /// No description provided for @calculate.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla'**
  String get calculate;

  /// No description provided for @calculating.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplanıyor...'**
  String get calculating;

  /// No description provided for @resultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç'**
  String get resultTitle;

  /// No description provided for @initialValue.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Değeri'**
  String get initialValue;

  /// No description provided for @finalValue.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü Değer'**
  String get finalValue;

  /// No description provided for @profitLoss.
  ///
  /// In tr, this message translates to:
  /// **'Kar / Zarar'**
  String get profitLoss;

  /// No description provided for @profitLossPercent.
  ///
  /// In tr, this message translates to:
  /// **'Getiri'**
  String get profitLossPercent;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @profit.
  ///
  /// In tr, this message translates to:
  /// **'Kazanç'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In tr, this message translates to:
  /// **'Kayıp'**
  String get loss;

  /// No description provided for @profitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kar'**
  String get profitLabel;

  /// No description provided for @lossLabel.
  ///
  /// In tr, this message translates to:
  /// **'Zarar'**
  String get lossLabel;

  /// No description provided for @enterAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar giriniz'**
  String get enterAmount;

  /// No description provided for @assetRequired.
  ///
  /// In tr, this message translates to:
  /// **'Varlık seçiniz'**
  String get assetRequired;

  /// No description provided for @buyDateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Alış tarihi giriniz'**
  String get buyDateRequired;

  /// No description provided for @validAmountRequired.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir tutar giriniz'**
  String get validAmountRequired;

  /// No description provided for @errorServer.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu hatası. Lütfen tekrar deneyin.'**
  String get errorServer;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Lütfen tekrar deneyin.'**
  String get errorGeneric;

  /// No description provided for @errorPriceNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarih için fiyat bilgisi bulunamadı.'**
  String get errorPriceNotFound;

  /// No description provided for @errorDailyLimit.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hesaplama limitine ulaştınız.'**
  String get errorDailyLimit;

  /// No description provided for @errorScenarioLimit.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz planda en fazla {limit} senaryo kaydedebilirsiniz.'**
  String errorScenarioLimit(int limit);

  /// No description provided for @errorNoInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok.'**
  String get errorNoInternet;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Hesapla'**
  String get tryAgain;

  /// No description provided for @scenariosTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senaryolarım'**
  String get scenariosTitle;

  /// No description provided for @scenariosEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilen senaryo yok'**
  String get scenariosEmpty;

  /// No description provided for @scenariosEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplama yaptıktan sonra senaryolarınızı kaydedebilirsiniz.'**
  String get scenariosEmptyHint;

  /// No description provided for @saveScenario.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get saveScenario;

  /// No description provided for @scenarioSaved.
  ///
  /// In tr, this message translates to:
  /// **'Senaryo kaydedildi.'**
  String get scenarioSaved;

  /// No description provided for @scenarioDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Senaryo silindi.'**
  String get scenarioDeleted;

  /// No description provided for @deleteScenario.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get deleteScenario;

  /// No description provided for @undo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undo;

  /// No description provided for @tabCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla'**
  String get tabCalculate;

  /// No description provided for @tabScenarios.
  ///
  /// In tr, this message translates to:
  /// **'Senaryolarım'**
  String get tabScenarios;

  /// No description provided for @searchAsset.
  ///
  /// In tr, this message translates to:
  /// **'Varlık ara...'**
  String get searchAsset;

  /// No description provided for @categoryCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Döviz'**
  String get categoryCurrency;

  /// No description provided for @categoryPreciousMetal.
  ///
  /// In tr, this message translates to:
  /// **'Kıymetli Maden'**
  String get categoryPreciousMetal;

  /// No description provided for @categoryCrypto.
  ///
  /// In tr, this message translates to:
  /// **'Kripto Para'**
  String get categoryCrypto;

  /// No description provided for @categoryStock.
  ///
  /// In tr, this message translates to:
  /// **'Hisse Senedi'**
  String get categoryStock;

  /// No description provided for @resultBuyPrice.
  ///
  /// In tr, this message translates to:
  /// **'Alış Fiyatı'**
  String get resultBuyPrice;

  /// No description provided for @resultSellPrice.
  ///
  /// In tr, this message translates to:
  /// **'Satış/Güncel Fiyatı'**
  String get resultSellPrice;

  /// No description provided for @resultUnitsAcquired.
  ///
  /// In tr, this message translates to:
  /// **'Edinilen Miktar'**
  String get resultUnitsAcquired;

  /// No description provided for @resultDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get resultDuration;

  /// No description provided for @durationDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String durationDays(int count);

  /// No description provided for @durationMonths.
  ///
  /// In tr, this message translates to:
  /// **'{count} ay'**
  String durationMonths(int count);

  /// No description provided for @durationYearsMonths.
  ///
  /// In tr, this message translates to:
  /// **'{years} yıl {months} ay'**
  String durationYearsMonths(int years, int months);

  /// No description provided for @durationYears.
  ///
  /// In tr, this message translates to:
  /// **'{count} yıl'**
  String durationYears(int count);

  /// No description provided for @dateAdjustedWarning.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen tarih bu varlık için uygun değil, en yakın geçerli tarihe ayarlandı.'**
  String get dateAdjustedWarning;

  /// No description provided for @scenarioDuplicate.
  ///
  /// In tr, this message translates to:
  /// **'Bu senaryo zaten kaydedilmiş.'**
  String get scenarioDuplicate;

  /// No description provided for @priceDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Gösterilen fiyatlar yaklaşık değerlerdir. Kurum, komisyon ve kur farklılıkları nedeniyle gerçek işlem tutarları değişiklik gösterebilir.'**
  String get priceDisclaimer;

  /// No description provided for @tabCompare.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştır'**
  String get tabCompare;

  /// No description provided for @compareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Karşılaştırma'**
  String get compareTitle;

  /// No description provided for @compareSelectAssets.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Seçin (2-5 adet)'**
  String get compareSelectAssets;

  /// No description provided for @compareMinAssets.
  ///
  /// In tr, this message translates to:
  /// **'En az 2 varlık seçiniz.'**
  String get compareMinAssets;

  /// No description provided for @compareButton.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştır'**
  String get compareButton;

  /// No description provided for @comparing.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırılıyor...'**
  String get comparing;

  /// No description provided for @compareResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma Sonuçları'**
  String get compareResultTitle;

  /// No description provided for @compareRankLabel.
  ///
  /// In tr, this message translates to:
  /// **'{rank}. Sıra'**
  String compareRankLabel(int rank);

  /// No description provided for @compareAddAsset.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Ekle'**
  String get compareAddAsset;

  /// No description provided for @compareAllCategories.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get compareAllCategories;

  /// No description provided for @compareNoAssetsFound.
  ///
  /// In tr, this message translates to:
  /// **'Varlık bulunamadı'**
  String get compareNoAssetsFound;

  /// No description provided for @inflationAdjust.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyona Göre Düzelt'**
  String get inflationAdjust;

  /// No description provided for @inflationAdjustSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'TÜFE bazlı reel getiriyi hesaplar'**
  String get inflationAdjustSubtitle;

  /// No description provided for @premiumFeature.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premiumFeature;

  /// No description provided for @realReturn.
  ///
  /// In tr, this message translates to:
  /// **'Reel Getiri'**
  String get realReturn;

  /// No description provided for @realProfitLoss.
  ///
  /// In tr, this message translates to:
  /// **'Reel Kar / Zarar'**
  String get realProfitLoss;

  /// No description provided for @cumulativeInflation.
  ///
  /// In tr, this message translates to:
  /// **'Birikimli Enflasyon'**
  String get cumulativeInflation;

  /// No description provided for @inflationSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyon Düzeltmesi'**
  String get inflationSectionTitle;

  /// No description provided for @dateAdjustedNote.
  ///
  /// In tr, this message translates to:
  /// **'Tarih düzeltmesi uygulandı'**
  String get dateAdjustedNote;

  /// No description provided for @inflationDataAsOf.
  ///
  /// In tr, this message translates to:
  /// **'Endeks baz tarihi: {date}'**
  String inflationDataAsOf(String date);

  /// No description provided for @priceDateAdjusted.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat bulunamadı: {requested} ({reason}) — {actual} tarihi kullanıldı.'**
  String priceDateAdjusted(String requested, String reason, String actual);

  /// No description provided for @reasonWeekend.
  ///
  /// In tr, this message translates to:
  /// **'haftasonu'**
  String get reasonWeekend;

  /// No description provided for @reasonHoliday.
  ///
  /// In tr, this message translates to:
  /// **'resmi tatil veya fiyat yok'**
  String get reasonHoliday;

  /// No description provided for @labelBuyDate.
  ///
  /// In tr, this message translates to:
  /// **'Alış'**
  String get labelBuyDate;

  /// No description provided for @labelSellDate.
  ///
  /// In tr, this message translates to:
  /// **'Satış'**
  String get labelSellDate;

  /// No description provided for @shareResult.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get shareResult;

  /// No description provided for @sharePreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım Önizlemesi'**
  String get sharePreviewTitle;

  /// No description provided for @sharingInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor...'**
  String get sharingInProgress;

  /// No description provided for @tabPortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Portföy'**
  String get tabPortfolio;

  /// No description provided for @portfolioTitle.
  ///
  /// In tr, this message translates to:
  /// **'Portföy Oluşturucu'**
  String get portfolioTitle;

  /// No description provided for @portfolioDateSection.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım Dönemi'**
  String get portfolioDateSection;

  /// No description provided for @portfolioAssetsSection.
  ///
  /// In tr, this message translates to:
  /// **'Varlıklar'**
  String get portfolioAssetsSection;

  /// No description provided for @portfolioAddAsset.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Ekle'**
  String get portfolioAddAsset;

  /// No description provided for @portfolioAddAssetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Portföye Varlık Ekle'**
  String get portfolioAddAssetTitle;

  /// No description provided for @portfolioCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Portföyü Hesapla'**
  String get portfolioCalculate;

  /// No description provided for @portfolioCalculating.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplanıyor...'**
  String get portfolioCalculating;

  /// No description provided for @portfolioReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get portfolioReset;

  /// No description provided for @portfolioEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz varlık eklenmedi.'**
  String get portfolioEmpty;

  /// No description provided for @portfolioEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Varlık ekleyerek portföyünüzün tarihsel getirisini hesaplayın.'**
  String get portfolioEmptyHint;

  /// No description provided for @portfolioQuotaInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesaplama {count} hesaplama hakkı kullanacak.'**
  String portfolioQuotaInfo(int count);

  /// No description provided for @portfolioTotalInitial.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Yatırım'**
  String get portfolioTotalInitial;

  /// No description provided for @portfolioTotalFinal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Son Değer'**
  String get portfolioTotalFinal;

  /// No description provided for @portfolioTotalReturn.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Getiri'**
  String get portfolioTotalReturn;

  /// No description provided for @portfolioChartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son Değer Dağılımı'**
  String get portfolioChartTitle;

  /// No description provided for @portfolioBuyDateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç tarihi giriniz'**
  String get portfolioBuyDateRequired;

  /// No description provided for @portfolioMinItems.
  ///
  /// In tr, this message translates to:
  /// **'En az 1 varlık ekleyin.'**
  String get portfolioMinItems;

  /// No description provided for @portfolioHistoryLimit.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz planda son {months} aya ait tarih seçilebilir.'**
  String portfolioHistoryLimit(int months);

  /// No description provided for @portfolioEditAssetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Varlığı Düzenle'**
  String get portfolioEditAssetTitle;

  /// No description provided for @portfolioSaveAsset.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get portfolioSaveAsset;

  /// No description provided for @portfolioInflationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyona Göre Düzelt'**
  String get portfolioInflationLabel;

  /// No description provided for @portfolioRealReturn.
  ///
  /// In tr, this message translates to:
  /// **'Reel Toplam Getiri'**
  String get portfolioRealReturn;

  /// No description provided for @portfolioRealProfitLoss.
  ///
  /// In tr, this message translates to:
  /// **'Reel Kar / Zarar'**
  String get portfolioRealProfitLoss;

  /// No description provided for @scenarioTypeWhatIf.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplama'**
  String get scenarioTypeWhatIf;

  /// No description provided for @scenarioTypeComparison.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştırma'**
  String get scenarioTypeComparison;

  /// No description provided for @scenarioTypePortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Portföy'**
  String get scenarioTypePortfolio;

  /// No description provided for @scenarioTypeDca.
  ///
  /// In tr, this message translates to:
  /// **'Birikim'**
  String get scenarioTypeDca;

  /// No description provided for @brandedTitlePrefix.
  ///
  /// In tr, this message translates to:
  /// **'al/sat '**
  String get brandedTitlePrefix;

  /// No description provided for @brandedTitleSuffix.
  ///
  /// In tr, this message translates to:
  /// **'saydın'**
  String get brandedTitleSuffix;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @settingsTheme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın görünümünü seçin'**
  String get settingsThemeSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @settingsVersion.
  ///
  /// In tr, this message translates to:
  /// **'Versiyon'**
  String get settingsVersion;

  /// No description provided for @categoryFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get categoryFavorites;

  /// No description provided for @favoritesMaxReached.
  ///
  /// In tr, this message translates to:
  /// **'En fazla {max} favori ekleyebilirsiniz.'**
  String favoritesMaxReached(int max);

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini seçin'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get languageSystem;

  /// No description provided for @shareCardInitialValue.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get shareCardInitialValue;

  /// No description provided for @shareCardFinalValue.
  ///
  /// In tr, this message translates to:
  /// **'Son Değer'**
  String get shareCardFinalValue;

  /// No description provided for @shareCardNominalReturn.
  ///
  /// In tr, this message translates to:
  /// **'Nominal Getiri'**
  String get shareCardNominalReturn;

  /// No description provided for @shareCardReturn.
  ///
  /// In tr, this message translates to:
  /// **'Getiri'**
  String get shareCardReturn;

  /// No description provided for @shareCardProfit.
  ///
  /// In tr, this message translates to:
  /// **'kazanç'**
  String get shareCardProfit;

  /// No description provided for @shareCardLoss.
  ///
  /// In tr, this message translates to:
  /// **'zarar'**
  String get shareCardLoss;

  /// No description provided for @shareCardInflationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyon Düzeltmesi (TÜFE)'**
  String get shareCardInflationTitle;

  /// No description provided for @shareCardCumulativeInflation.
  ///
  /// In tr, this message translates to:
  /// **'Birikimli Enflasyon'**
  String get shareCardCumulativeInflation;

  /// No description provided for @shareCardRealReturn.
  ///
  /// In tr, this message translates to:
  /// **'Reel Getiri'**
  String get shareCardRealReturn;

  /// No description provided for @shareCardWhatIfFooter.
  ///
  /// In tr, this message translates to:
  /// **'Ya alsaydın?'**
  String get shareCardWhatIfFooter;

  /// No description provided for @shareCardComparisonTitle.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Karşılaştırması'**
  String get shareCardComparisonTitle;

  /// No description provided for @shareCardComparisonFooter.
  ///
  /// In tr, this message translates to:
  /// **'Hangisi daha kazandırdı?'**
  String get shareCardComparisonFooter;

  /// No description provided for @shareCardPortfolioTitle.
  ///
  /// In tr, this message translates to:
  /// **'Portföy Getirisi'**
  String get shareCardPortfolioTitle;

  /// No description provided for @shareCardPortfolioFooter.
  ///
  /// In tr, this message translates to:
  /// **'Portföyüm ne kazandırdı?'**
  String get shareCardPortfolioFooter;

  /// No description provided for @shareCardTotalInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Yatırım'**
  String get shareCardTotalInvestment;

  /// No description provided for @shareCardTotalReturn.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Getiri'**
  String get shareCardTotalReturn;

  /// No description provided for @shareCardNominalTotalReturn.
  ///
  /// In tr, this message translates to:
  /// **'Nominal Getiri'**
  String get shareCardNominalTotalReturn;

  /// No description provided for @shareCardAssetCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} varlık'**
  String shareCardAssetCount(int count);

  /// No description provided for @shareTextWhatIf.
  ///
  /// In tr, this message translates to:
  /// **'{asset}\'e {initial} yatırsaydım {final_value} ederdi ({percent})! 📊 #saydın'**
  String shareTextWhatIf(
    String asset,
    String initial,
    String final_value,
    String percent,
  );

  /// No description provided for @shareTextComparison.
  ///
  /// In tr, this message translates to:
  /// **'Hangi yatırım daha kazandırdı? 🏆 {winner}: {percent} 📊 #saydın'**
  String shareTextComparison(String winner, String percent);

  /// No description provided for @shareTextPortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Portföyüm {count} varlıkla {percent} getiri sağladı! 📊 #saydın'**
  String shareTextPortfolio(int count, String percent);

  /// No description provided for @shareDefaultText.
  ///
  /// In tr, this message translates to:
  /// **'saydın.app üzerinden hesapladım.'**
  String get shareDefaultText;

  /// No description provided for @shareCta.
  ///
  /// In tr, this message translates to:
  /// **'\n\n📱 Saydın uygulamasını indir — App Store ve Google Play\'de \"saydın\" ara.'**
  String get shareCta;

  /// No description provided for @scenarioNameComparison.
  ///
  /// In tr, this message translates to:
  /// **'{count} Varlık Karşılaştırması'**
  String scenarioNameComparison(int count);

  /// No description provided for @scenarioNamePortfolio.
  ///
  /// In tr, this message translates to:
  /// **'Portföy ({count} varlık)'**
  String scenarioNamePortfolio(int count);

  /// No description provided for @realReturnPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Reel: '**
  String get realReturnPrefix;

  /// No description provided for @onboardingSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Dene'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In tr, this message translates to:
  /// **'Ya Alsaydım?'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In tr, this message translates to:
  /// **'Merak ettiğin yatırımı geçmişe dönük hesapla. Dolar, altın, Bitcoin ve daha fazlası.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In tr, this message translates to:
  /// **'Karşılaştır ve Keşfet'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In tr, this message translates to:
  /// **'Varlıkları yan yana karşılaştır, portföy oluştur. Hangisi daha kazandırdı?'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In tr, this message translates to:
  /// **'Portföy Oluştur'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla varlıkla portföy kur, toplam getirini hesapla ve en iyi stratejiyi keşfet.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli Yatırım'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Body.
  ///
  /// In tr, this message translates to:
  /// **'Aylık veya haftalık düzenli alım simüle et, ortalama maliyetini ve toplam getirisini gör.'**
  String get onboardingPage4Body;

  /// No description provided for @onboardingPage5Title.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş ve Kaydet'**
  String get onboardingPage5Title;

  /// No description provided for @onboardingPage5Body.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlarını arkadaşlarınla paylaş, senaryolarını kaydet ve istediğin zaman geri dön.'**
  String get onboardingPage5Body;

  /// No description provided for @tabDca.
  ///
  /// In tr, this message translates to:
  /// **'Birikim'**
  String get tabDca;

  /// No description provided for @dcaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli Yatırım Simülasyonu'**
  String get dcaTitle;

  /// No description provided for @dcaStartDate.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Tarihi'**
  String get dcaStartDate;

  /// No description provided for @dcaEndDate.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş Tarihi (opsiyonel)'**
  String get dcaEndDate;

  /// No description provided for @dcaStartDateRequired.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç tarihi giriniz'**
  String get dcaStartDateRequired;

  /// No description provided for @dcaPeriodWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get dcaPeriodWeekly;

  /// No description provided for @dcaPeriodMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get dcaPeriodMonthly;

  /// No description provided for @dcaPeriodLabel.
  ///
  /// In tr, this message translates to:
  /// **'Periyot'**
  String get dcaPeriodLabel;

  /// No description provided for @dcaPeriodicAmountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Periyodik Tutar'**
  String get dcaPeriodicAmountLabel;

  /// No description provided for @dcaPeriodicAmount.
  ///
  /// In tr, this message translates to:
  /// **'Periyodik Tutar'**
  String get dcaPeriodicAmount;

  /// No description provided for @dcaCalculate.
  ///
  /// In tr, this message translates to:
  /// **'Simüle Et'**
  String get dcaCalculate;

  /// No description provided for @dcaTotalInvested.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Yatırım'**
  String get dcaTotalInvested;

  /// No description provided for @dcaCurrentValue.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Değer'**
  String get dcaCurrentValue;

  /// No description provided for @dcaTotalPurchases.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Alım'**
  String get dcaTotalPurchases;

  /// No description provided for @dcaAvgCost.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama Maliyet'**
  String get dcaAvgCost;

  /// No description provided for @dcaTotalUnits.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Adet'**
  String get dcaTotalUnits;

  /// No description provided for @dcaCurrentPrice.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Fiyat'**
  String get dcaCurrentPrice;

  /// No description provided for @dcaChartCost.
  ///
  /// In tr, this message translates to:
  /// **'Maliyet'**
  String get dcaChartCost;

  /// No description provided for @dcaChartValue.
  ///
  /// In tr, this message translates to:
  /// **'Değer'**
  String get dcaChartValue;

  /// No description provided for @shareCardDcaFooter.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli yatırım ile birikim'**
  String get shareCardDcaFooter;

  /// No description provided for @shareTextDca.
  ///
  /// In tr, this message translates to:
  /// **'{asset} için {count} alım yaptım, getiri: {percent}! 📊 #saydın'**
  String shareTextDca(String asset, int count, String percent);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
