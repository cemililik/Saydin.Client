import 'package:equatable/equatable.dart';

class AppConfig extends Equatable {
  final String tier;

  /// 0 = sınırsız
  final int dailyCalculationLimit;

  /// 0 = sınırsız
  final int maxSavedScenarios;

  final AppFeatureFlags features;

  const AppConfig({
    required this.tier,
    required this.dailyCalculationLimit,
    required this.maxSavedScenarios,
    required this.features,
  });

  bool get isPremium => tier == 'premium';
  bool get isUnlimitedCalculations => dailyCalculationLimit == 0;
  bool get isUnlimitedScenarios => maxSavedScenarios == 0;

  /// Tüm özellikler açık, limit yok — backend yanıt vermeden önce kullanılacak varsayılan.
  static const defaultConfig = AppConfig(
    tier: 'free',
    dailyCalculationLimit: 20,
    maxSavedScenarios: 10,
    features: AppFeatureFlags(
      comparison: true,
      inflationAdjustment: true,
      share: true,
      priceHistoryMonths: 12,
    ),
  );

  @override
  List<Object?> get props => [
    tier,
    dailyCalculationLimit,
    maxSavedScenarios,
    features,
  ];
}

class AppFeatureFlags extends Equatable {
  final bool comparison;
  final bool inflationAdjustment;
  final bool share;

  /// 0 = tüm geçmiş
  final int priceHistoryMonths;

  const AppFeatureFlags({
    required this.comparison,
    required this.inflationAdjustment,
    required this.share,
    required this.priceHistoryMonths,
  });

  @override
  List<Object?> get props => [
    comparison,
    inflationAdjustment,
    share,
    priceHistoryMonths,
  ];
}
