import 'package:equatable/equatable.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';

/// Config'in hangi güvenilirlik aşamasında olduğunu açıkça taşır.
enum AppConfigReadiness { loading, ready, fallback }

class AppConfig extends Equatable {
  final SubscriptionTier tier;

  /// 0 = sınırsız
  final int dailyCalculationLimit;

  /// 0 = sınırsız
  final int maxSavedScenarios;

  final AppFeatureFlags features;
  final AppConfigReadiness readiness;

  const AppConfig({
    required this.tier,
    required this.dailyCalculationLimit,
    required this.maxSavedScenarios,
    required this.features,
    this.readiness = AppConfigReadiness.ready,
  });

  /// Plan/feature kararlarının güvenle verilebildiği durum.
  bool get isReady => readiness != AppConfigReadiness.loading;

  bool get usesFallback => readiness == AppConfigReadiness.fallback;
  bool get isPremium => tier == SubscriptionTier.premium;
  bool get isUnlimitedCalculations => dailyCalculationLimit == 0;
  bool get isUnlimitedScenarios => maxSavedScenarios == 0;

  /// Backend yanıtı alınamadığında kullanılan güvenli fallback.
  static const defaultConfig = AppConfig(
    tier: SubscriptionTier.free,
    dailyCalculationLimit: 20,
    maxSavedScenarios: 10,
    readiness: AppConfigReadiness.fallback,
    features: AppFeatureFlags(
      comparison: true,
      inflationAdjustment: true,
      share: true,
      dca: true,
      priceHistoryMonths: 12,
    ),
  );

  /// İlk frame için placeholder. UI render edebilir fakat plan/feature kararı
  /// gerektiren aksiyonlar [isReady] true olana kadar backend'e gitmez.
  static const initialConfig = AppConfig(
    tier: SubscriptionTier.free,
    dailyCalculationLimit: 20,
    maxSavedScenarios: 10,
    readiness: AppConfigReadiness.loading,
    features: AppFeatureFlags(
      comparison: true,
      inflationAdjustment: true,
      share: true,
      dca: true,
      priceHistoryMonths: 12,
    ),
  );

  @override
  List<Object?> get props => [
    tier,
    dailyCalculationLimit,
    maxSavedScenarios,
    features,
    readiness,
  ];
}

class AppFeatureFlags extends Equatable {
  final bool comparison;
  final bool inflationAdjustment;
  final bool share;
  final bool dca;

  /// 0 = tüm geçmiş
  final int priceHistoryMonths;

  const AppFeatureFlags({
    required this.comparison,
    required this.inflationAdjustment,
    required this.share,
    required this.dca,
    required this.priceHistoryMonths,
  });

  @override
  List<Object?> get props => [
    comparison,
    inflationAdjustment,
    share,
    dca,
    priceHistoryMonths,
  ];
}
