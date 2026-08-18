// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Saydın';

  @override
  String get selectAsset => 'Select Asset';

  @override
  String get buyDate => 'Buy Date';

  @override
  String get sellDate => 'Sell Date (optional)';

  @override
  String get amount => 'Amount';

  @override
  String get amountHint => '10000';

  @override
  String get amountTypeTry => '₺ TRY';

  @override
  String get amountTypeUnits => 'Units';

  @override
  String get amountTypeGrams => 'Grams';

  @override
  String get calculate => 'Calculate';

  @override
  String get calculating => 'Calculating...';

  @override
  String get initialValue => 'Initial Value';

  @override
  String get finalValue => 'Current Value';

  @override
  String get profitLoss => 'Profit / Loss';

  @override
  String get profitLossPercent => 'Return';

  @override
  String get today => 'Today';

  @override
  String get profit => 'Profit';

  @override
  String get loss => 'Loss';

  @override
  String get profitLabel => 'Profit';

  @override
  String get lossLabel => 'Loss';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get assetRequired => 'Please select an asset';

  @override
  String get buyDateRequired => 'Please enter buy date';

  @override
  String get validAmountRequired => 'Please enter a valid amount';

  @override
  String get errorServer => 'Server error. Please try again.';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get errorPriceNotFound => 'No price data found for this date.';

  @override
  String get errorDailyLimit => 'Daily calculation limit reached.';

  @override
  String errorScenarioLimit(int limit) {
    return 'Free plan allows up to $limit saved scenarios.';
  }

  @override
  String get errorNoInternet => 'No internet connection.';

  @override
  String get errorAssetNotFound => 'This asset is no longer available.';

  @override
  String get errorMalformed =>
      'Received an unexpected response from the server. Please try again.';

  @override
  String get errorFeatureDisabled =>
      'This feature isn\'t available on your current plan.';

  @override
  String get errorFeatureDisabledExtendedHistory =>
      'Older dates require a Premium plan.';

  @override
  String get errorFeatureDisabledInflation =>
      'Inflation adjustment is a Premium feature.';

  @override
  String get errorFeatureDisabledComparison =>
      'Asset comparison is a Premium feature.';

  @override
  String get errorFeatureDisabledDca =>
      'Recurring investment (DCA) is a Premium feature.';

  @override
  String get retry => 'Retry';

  @override
  String get scenariosTitle => 'My Scenarios';

  @override
  String get scenariosEmpty => 'No saved scenarios yet';

  @override
  String get scenariosEmptyHint =>
      'You can save your scenarios after making a calculation.';

  @override
  String get saveScenario => 'Save';

  @override
  String get scenarioSaved => 'Scenario saved.';

  @override
  String get scenarioDeleted => 'Scenario deleted.';

  @override
  String scenarioSavedAtSnapshot(String date) {
    return 'Saved on $date — result as of that date';
  }

  @override
  String get deleteScenario => 'Delete';

  @override
  String get tabCalculate => 'Calculate';

  @override
  String get tabScenarios => 'Scenarios';

  @override
  String get searchAsset => 'Search asset...';

  @override
  String get categoryCurrency => 'Currency';

  @override
  String get categoryPreciousMetal => 'Precious Metal';

  @override
  String get categoryCrypto => 'Cryptocurrency';

  @override
  String get categoryStock => 'Stock';

  @override
  String get resultBuyPrice => 'Buy Price';

  @override
  String get resultSellPrice => 'Sell/Current Price';

  @override
  String get resultUnitsAcquired => 'Units Acquired';

  @override
  String get resultDuration => 'Duration';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String durationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String durationYearsMonths(int years, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    String _temp1 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String durationYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get dateAdjustedWarning =>
      'Selected date is not available for this asset, adjusted to the nearest valid date.';

  @override
  String get scenarioDuplicate => 'This scenario has already been saved.';

  @override
  String get priceDisclaimer =>
      'Prices shown are approximate. Actual transaction amounts may vary due to institution fees, commissions, and exchange rate differences.';

  @override
  String get tabCompare => 'Compare';

  @override
  String get compareTitle => 'Asset Comparison';

  @override
  String compareSelectAssets(int min, int max) {
    return 'Select Assets ($min-$max)';
  }

  @override
  String get compareMinAssets => 'Please select at least 2 assets.';

  @override
  String get compareButton => 'Compare';

  @override
  String get comparing => 'Comparing...';

  @override
  String get compareResultTitle => 'Comparison Results';

  @override
  String get compareAddAsset => 'Add Asset';

  @override
  String get compareAllCategories => 'All';

  @override
  String get compareNoAssetsFound => 'No assets found';

  @override
  String get inflationAdjust => 'Adjust for Inflation';

  @override
  String get inflationAdjustSubtitle => 'Calculates real return based on CPI';

  @override
  String get premiumFeature => 'Premium';

  @override
  String get realReturn => 'Real Return';

  @override
  String get realProfitLoss => 'Real Profit / Loss';

  @override
  String get cumulativeInflation => 'Cumulative Inflation';

  @override
  String get inflationSectionTitle => 'Inflation Adjustment';

  @override
  String get dateAdjustedNote => 'Date adjustment applied';

  @override
  String inflationDataAsOf(String date) {
    return 'Index base date: $date';
  }

  @override
  String priceDateAdjusted(String requested, String reason, String actual) {
    return 'Price not found: $requested ($reason) — $actual date used.';
  }

  @override
  String get reasonWeekend => 'weekend';

  @override
  String get reasonHoliday => 'public holiday or no price';

  @override
  String get labelBuyDate => 'Buy';

  @override
  String get labelSellDate => 'Sell';

  @override
  String get shareResult => 'Share';

  @override
  String get sharePreviewTitle => 'Share Preview';

  @override
  String get sharingInProgress => 'Preparing...';

  @override
  String get shareError => 'Couldn\'t create the share card. Please try again.';

  @override
  String get tabPortfolio => 'Portfolio';

  @override
  String get portfolioTitle => 'Portfolio Builder';

  @override
  String get portfolioDateSection => 'Investment Period';

  @override
  String get portfolioAssetsSection => 'Assets';

  @override
  String get portfolioAddAsset => 'Add Asset';

  @override
  String get portfolioAddAssetTitle => 'Add Asset to Portfolio';

  @override
  String get portfolioCalculate => 'Calculate Portfolio';

  @override
  String get portfolioCalculating => 'Calculating...';

  @override
  String get portfolioReset => 'Reset';

  @override
  String get portfolioEmpty => 'No assets added yet.';

  @override
  String get portfolioEmptyHint =>
      'Add assets to calculate your portfolio\'s historical return.';

  @override
  String portfolioQuotaInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calculation credits',
      one: '1 calculation credit',
    );
    return 'This calculation will use $_temp0.';
  }

  @override
  String get portfolioTotalInitial => 'Total Investment';

  @override
  String get portfolioTotalFinal => 'Total Final Value';

  @override
  String get portfolioTotalReturn => 'Total Return';

  @override
  String get portfolioChartTitle => 'Final Value Distribution';

  @override
  String get portfolioBuyDateRequired => 'Please enter start date';

  @override
  String get portfolioMinItems => 'Add at least 1 asset.';

  @override
  String portfolioMaxItems(int count) {
    return 'You can add at most $count assets.';
  }

  @override
  String get portfolioAmountTooLarge =>
      'Amount is too large. Please enter a smaller value.';

  @override
  String portfolioAmountTooManyDecimals(int decimals) {
    return 'Amount can have at most $decimals decimal places.';
  }

  @override
  String portfolioHistoryLimit(int months) {
    return 'Free plan allows dates within the last $months months.';
  }

  @override
  String get portfolioEditAssetTitle => 'Edit Asset';

  @override
  String get portfolioSaveAsset => 'Save';

  @override
  String get portfolioInflationLabel => 'Adjust for Inflation';

  @override
  String get portfolioRealReturn => 'Real Total Return';

  @override
  String get portfolioRealProfitLoss => 'Real Profit / Loss';

  @override
  String get scenarioTypeWhatIf => 'What If?';

  @override
  String get scenarioTypeComparison => 'Comparison';

  @override
  String get scenarioTypePortfolio => 'Portfolio';

  @override
  String get scenarioTypeDca => 'DCA';

  @override
  String get brandedTitlePrefix => 'buy/sell ';

  @override
  String get brandedTitleSuffix => 'saydın';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Choose app appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get categoryFavorites => 'Favorites';

  @override
  String favoritesMaxReached(int max) {
    return 'You can add up to $max favorites.';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose app language';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsKvkkDisclosure => 'KVKK Disclosure (TR PDPA)';

  @override
  String get settingsDeleteAccount => 'Delete My Account';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get deleteAccountTitle => 'Delete My Account';

  @override
  String get deleteAccountWarning =>
      'This action cannot be undone. All your preferences, saved scenarios, and favorites on this device will be permanently deleted. Under KVKK Article 11 / GDPR Article 17, your data erasure request will be completed within 30 days.';

  @override
  String deleteAccountConfirmHint(String word) {
    return 'To confirm, please type \"$word\" below.';
  }

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountConfirmButton => 'Permanently Delete My Account';

  @override
  String get deleteAccountInProgress => 'Deleting your data...';

  @override
  String get deleteAccountSuccess =>
      'Your account and all data have been deleted.';

  @override
  String get deleteAccountPartialSuccess =>
      'All your local data has been deleted. However, our server deletion request could not be sent right now; please follow up via iletisim@saydin.app.';

  @override
  String get deleteAccountFailed =>
      'Account deletion could not be completed. Please try again or contact support.';

  @override
  String get shareCardInitialValue => 'Initial';

  @override
  String get shareCardFinalValue => 'Final Value';

  @override
  String get shareCardNominalReturn => 'Nominal Return';

  @override
  String get shareCardReturn => 'Return';

  @override
  String get shareCardProfit => 'profit';

  @override
  String get shareCardLoss => 'loss';

  @override
  String get shareCardInflationTitle => 'Inflation Adjustment (CPI)';

  @override
  String get shareCardCumulativeInflation => 'Cumulative Inflation';

  @override
  String get shareCardRealReturn => 'Real Return';

  @override
  String get shareCardWhatIfFooter => 'What if I bought?';

  @override
  String get shareCardComparisonTitle => 'Asset Comparison';

  @override
  String get shareCardComparisonFooter => 'Which one made more?';

  @override
  String get shareCardPortfolioTitle => 'Portfolio Return';

  @override
  String get shareCardPortfolioFooter => 'What did my portfolio earn?';

  @override
  String get shareCardTotalInvestment => 'Total Investment';

  @override
  String get shareCardTotalReturn => 'Total Return';

  @override
  String get shareCardNominalTotalReturn => 'Nominal Return';

  @override
  String shareCardAssetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
    );
    return '$_temp0';
  }

  @override
  String shareTextWhatIf(
    String asset,
    String initial,
    String finalValue,
    String percent,
  ) {
    return 'If I had invested $initial in $asset, it would be worth $finalValue ($percent)! 📊 #saydın';
  }

  @override
  String shareTextComparison(String winner, String percent) {
    return 'Which investment performed better? 🏆 $winner: $percent 📊 #saydın';
  }

  @override
  String shareTextPortfolio(int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
    );
    return 'My portfolio with $_temp0 returned $percent! 📊 #saydın';
  }

  @override
  String get shareDefaultText => 'Calculated on saydın.app.';

  @override
  String get shareCta =>
      '\n\n📱 Download Saydın — search \"saydın\" on App Store and Google Play.';

  @override
  String scenarioNameComparison(int count) {
    return '$count Asset Comparison';
  }

  @override
  String scenarioNamePortfolio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
    );
    return 'Portfolio ($_temp0)';
  }

  @override
  String get realReturnPrefix => 'Real: ';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String onboardingLegalConsent(String privacy, String kvkk) {
    return 'By continuing I confirm that I have read and accept the $privacy and $kvkk.';
  }

  @override
  String get onboardingPrivacyPolicyLink => 'Privacy Policy';

  @override
  String get onboardingKvkkLink => 'KVKK Disclosure';

  @override
  String get onboardingPage1Title => 'What If I Bought?';

  @override
  String get onboardingPage1Body =>
      'Calculate any investment retroactively. Dollar, gold, Bitcoin and more.';

  @override
  String get onboardingPage2Title => 'Compare and Discover';

  @override
  String get onboardingPage2Body =>
      'Compare assets side by side, build portfolios. Which one performed better?';

  @override
  String get onboardingPage3Title => 'Build a Portfolio';

  @override
  String get onboardingPage3Body =>
      'Create portfolios with multiple assets, calculate total returns and discover the best strategy.';

  @override
  String get onboardingPage4Title => 'Regular Investing';

  @override
  String get onboardingPage4Body =>
      'Simulate weekly or monthly recurring purchases, see average cost and total return.';

  @override
  String get onboardingPage5Title => 'Reverse Scenario';

  @override
  String get onboardingPage5Body =>
      'How much should you have invested to reach your goal? Find out with reverse calculation.';

  @override
  String get onboardingPage6Title => 'Share and Save';

  @override
  String get onboardingPage6Body =>
      'Share your results with friends, save your scenarios and come back anytime.';

  @override
  String get tabDca => 'DCA';

  @override
  String get dcaTitle => 'DCA Simulation';

  @override
  String get dcaNoAssets => 'No assets available right now.';

  @override
  String get dcaStartDate => 'Start Date';

  @override
  String get dcaEndDate => 'End Date (optional)';

  @override
  String get dcaStartDateRequired => 'Please enter start date';

  @override
  String get dcaEndBeforeStart => 'End date cannot be before start date';

  @override
  String get dcaPeriodWeekly => 'Weekly';

  @override
  String get dcaPeriodMonthly => 'Monthly';

  @override
  String get dcaPeriodLabel => 'Period';

  @override
  String get dcaPeriodicAmount => 'Periodic Amount';

  @override
  String get dcaCalculate => 'Simulate';

  @override
  String get dcaTotalInvested => 'Total Invested';

  @override
  String get dcaCurrentValue => 'Current Value';

  @override
  String get dcaTotalPurchases => 'Total Purchases';

  @override
  String get dcaAvgCost => 'Average Cost';

  @override
  String get dcaTotalUnits => 'Total Units';

  @override
  String get dcaCurrentPrice => 'Current Price';

  @override
  String get dcaChartCost => 'Cost';

  @override
  String get dcaChartValue => 'Value';

  @override
  String get shareCardDcaFooter => 'DCA — regular investing';

  @override
  String shareTextDca(String asset, int count, String percent) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchases',
      one: '1 purchase',
    );
    return 'DCA into $asset: $_temp0, return: $percent! 📊 #saydın';
  }

  @override
  String get modeNormal => 'Calculate';

  @override
  String get modeNormalHint => 'How much would my investment be worth today?';

  @override
  String get modeReverse => 'Reverse';

  @override
  String get modeReverseHint =>
      'How much should I have invested to reach my target?';

  @override
  String get targetAmount => 'Target Amount';

  @override
  String get enterTargetAmount => 'Enter target amount';

  @override
  String get reverseCalculate => 'Reverse Calculate';

  @override
  String get reverseCalculating => 'Calculating...';

  @override
  String get requiredInvestment => 'Required Investment';

  @override
  String get targetValue => 'Target Value';

  @override
  String get reverseResultTitle => 'Reverse Scenario Result';

  @override
  String shareTextReverse(
    String asset,
    String target,
    String required,
    String percent,
  ) {
    return 'To reach $target with $asset, I should have invested $required ($percent)! 📊 #saydın';
  }

  @override
  String get shareCardReverseFooter => 'How much should I have invested?';

  @override
  String get shareCardRequiredInvestment => 'Required Investment';

  @override
  String get shareCardTargetValue => 'Target Value';

  @override
  String get scenarioTypeReverse => 'Reverse Calculation';

  @override
  String get compareHint =>
      'Which asset would have earned more if you invested the same amount?';

  @override
  String get dcaHint =>
      'Simulate regular purchases at fixed intervals to see average cost and total return.';
}
