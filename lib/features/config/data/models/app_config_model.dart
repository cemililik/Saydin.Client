import 'package:saydin/features/config/domain/entities/app_config.dart';

class AppConfigModel extends AppConfig {
  const AppConfigModel({
    required super.tier,
    required super.dailyCalculationLimit,
    required super.maxSavedScenarios,
    required super.features,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    // `as T? ?? d` yalnızca EKSİK key'i korur; YANLIŞ tip (örn. limit 20.0
    // double ya da "20" string, features List) runtime TypeError atardı.
    // Config asla uygulamayı bloklamamalı (defaultConfig semantiği) — yanlış
    // tipli alan throw etmek yerine default'a düşer.
    final f = _map(json['features']);
    return AppConfigModel(
      tier: _str(json['tier'], 'free'),
      dailyCalculationLimit: _int(json['dailyCalculationLimit'], 20),
      maxSavedScenarios: _int(json['maxSavedScenarios'], 10),
      features: AppFeatureFlags(
        comparison: _bool(f['comparison'], true),
        inflationAdjustment: _bool(f['inflationAdjustment'], true),
        share: _bool(f['share'], true),
        dca: _bool(f['dca'], true),
        priceHistoryMonths: _int(f['priceHistoryMonths'], 12),
      ),
    );
  }

  static String _str(Object? v, String d) => v is String ? v : d;
  // bool VEYA num (0/1) kabul: backend flag'i int gönderirse de doğru okunur
  // (örn. dca:0 → false). Böylece uzaktan özellik kapatma int gövdede de çalışır.
  static bool _bool(Object? v, bool d) =>
      v is bool ? v : (v is num ? v != 0 : d);
  // num kabul edip toInt() (20 ve 20.0 geçerli); negatif limit anlamsız → default.
  static int _int(Object? v, int d) {
    final n = v is num ? v.toInt() : d;
    return n < 0 ? d : n;
  }

  // Map key'leri non-String olabilir → `Map.from` yerine toString ile güvenle çevir.
  static Map<String, dynamic> _map(Object? v) => v is Map
      ? v.map((key, val) => MapEntry(key.toString(), val))
      : <String, dynamic>{};
}
