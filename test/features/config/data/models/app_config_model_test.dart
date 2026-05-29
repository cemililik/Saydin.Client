import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/config/data/models/app_config_model.dart';

void main() {
  group('AppConfigModel.fromJson (F-12-08 tip güvenliği)', () {
    test('geçerli tam payload doğru parse edilir', () {
      final m = AppConfigModel.fromJson(const {
        'tier': 'premium',
        'dailyCalculationLimit': 100,
        'maxSavedScenarios': 50,
        'features': {
          'comparison': false,
          'inflationAdjustment': false,
          'share': false,
          'dca': false,
          'priceHistoryMonths': 36,
        },
      });

      expect(m.tier, 'premium');
      expect(m.dailyCalculationLimit, 100);
      expect(m.maxSavedScenarios, 50);
      expect(m.features.comparison, isFalse);
      expect(m.features.priceHistoryMonths, 36);
    });

    test('boş {} payload tüm default değerlere düşer', () {
      final m = AppConfigModel.fromJson(const {});

      expect(m.tier, 'free');
      expect(m.dailyCalculationLimit, 20);
      expect(m.maxSavedScenarios, 10);
      expect(m.features.comparison, isTrue);
      expect(m.features.inflationAdjustment, isTrue);
      expect(m.features.share, isTrue);
      expect(m.features.dca, isTrue);
      expect(m.features.priceHistoryMonths, 12);
    });

    test('yanlış tipli alanlar throw etmez, default\'a düşer', () {
      final m = AppConfigModel.fromJson(const {
        // double — _int num kabul edip toInt() yapar → 20
        'dailyCalculationLimit': 20.0,
        // string — num değil → default 10
        'maxSavedScenarios': '50',
        // features List — _map {} → tüm flag default
        'features': ['unexpected'],
        // tier int — String değil → 'free'
        'tier': 42,
      });

      expect(m.tier, 'free');
      expect(m.dailyCalculationLimit, 20);
      expect(m.maxSavedScenarios, 10);
      expect(m.features.comparison, isTrue);
      expect(m.features.priceHistoryMonths, 12);
    });

    test('bool flag yanlış tipte (0/1) → default true', () {
      final m = AppConfigModel.fromJson(const {
        'features': {'comparison': 1, 'dca': 0},
      });

      expect(m.features.comparison, isTrue);
      expect(m.features.dca, isTrue);
    });
  });
}
