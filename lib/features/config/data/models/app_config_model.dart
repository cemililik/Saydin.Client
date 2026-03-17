import 'package:saydin/features/config/domain/entities/app_config.dart';

class AppConfigModel extends AppConfig {
  const AppConfigModel({
    required super.tier,
    required super.dailyCalculationLimit,
    required super.maxSavedScenarios,
    required super.features,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final f = json['features'] as Map<String, dynamic>? ?? {};
    return AppConfigModel(
      tier: json['tier'] as String? ?? 'free',
      dailyCalculationLimit: json['dailyCalculationLimit'] as int? ?? 20,
      maxSavedScenarios: json['maxSavedScenarios'] as int? ?? 10,
      features: AppFeatureFlags(
        comparison: f['comparison'] as bool? ?? true,
        inflationAdjustment: f['inflationAdjustment'] as bool? ?? true,
        share: f['share'] as bool? ?? true,
        priceHistoryMonths: f['priceHistoryMonths'] as int? ?? 12,
      ),
    );
  }
}
