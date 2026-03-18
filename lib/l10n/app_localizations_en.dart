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
  String get whatIfTitle => 'What If I Bought?';

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
  String get resultTitle => 'Result';

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
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Recalculate';

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
  String get deleteScenario => 'Delete';

  @override
  String get undo => 'Undo';

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
    return '$count days';
  }

  @override
  String durationMonths(int count) {
    return '$count months';
  }

  @override
  String durationYearsMonths(int years, int months) {
    return '$years years $months months';
  }

  @override
  String durationYears(int count) {
    return '$count years';
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
  String get compareSelectAssets => 'Select Assets (2-5)';

  @override
  String get compareMinAssets => 'Please select at least 2 assets.';

  @override
  String get compareButton => 'Compare';

  @override
  String get comparing => 'Comparing...';

  @override
  String get compareResultTitle => 'Comparison Results';

  @override
  String compareRankLabel(int rank) {
    return 'Rank $rank';
  }

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
    return 'This calculation will use $count calculation credits.';
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
  String get scenarioTypeWhatIf => 'Calculation';

  @override
  String get scenarioTypeComparison => 'Comparison';

  @override
  String get scenarioTypePortfolio => 'Portfolio';

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
  String get settingsVersion => 'Version';

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
}
