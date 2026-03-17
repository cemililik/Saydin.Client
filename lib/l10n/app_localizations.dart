import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

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
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
