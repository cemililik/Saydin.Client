import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/l10n/app_localizations.dart';

/// [AppError] → kullanıcıya gösterilecek lokalize mesaj.
///
/// Tüm feature sayfaları bu **tek** exhaustive switch'i kullanır. Önceden her
/// sayfa (what_if/comparison/dca/portfolio/scenarios) aynı switch'i kopyalıyordu;
/// yeni bir varyant eklenince beş yerde değişiklik gerekiyordu. Tek kaynağa
/// alınınca `exhaustive_cases` kuralı yeni varyantı yalnızca burada dayatır,
/// gösterim tutarlılığı garanti olur.
extension AppErrorL10n on AppError {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    PriceNotFoundError() => l10n.errorPriceNotFound,
    AssetNotFoundError() => l10n.errorAssetNotFound,
    DailyLimitError() => l10n.errorDailyLimit,
    ScenarioLimitError(:final limit) => l10n.errorScenarioLimit(limit),
    FeatureDisabledError(:final featureKey) => _featureDisabledMessage(
      featureKey,
      l10n,
    ),
    NotFoundError() || ForbiddenError() => l10n.errorServer,
    NoInternetError() => l10n.errorNoInternet,
    RequestCancelledError() => l10n.errorGeneric,
    InvalidScenarioReplayError() => l10n.scenarioReplayInvalid,
    ServerError() => l10n.errorServer,
    MalformedResponseError() => l10n.errorMalformed,
    UnknownError() => l10n.errorGeneric,
  };

  /// Backend `feature` extension'ına göre özelliğe özgü paywall mesajı seçer.
  /// Bilinmeyen/`null` key → genel "planınızda kullanılamıyor" mesajı (backend
  /// yeni bir featureKey eklerse istemci sessizce genel mesaja düşer, kırılmaz).
  String _featureDisabledMessage(String? featureKey, AppLocalizations l10n) =>
      switch (featureKey) {
        'extended_history' => l10n.errorFeatureDisabledExtendedHistory,
        'inflation' => l10n.errorFeatureDisabledInflation,
        'comparison' => l10n.errorFeatureDisabledComparison,
        'dca' => l10n.errorFeatureDisabledDca,
        _ => l10n.errorFeatureDisabled,
      };
}
