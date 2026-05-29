import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/config/data/models/app_config_model.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';

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

      expect(m.tier, SubscriptionTier.premium);
      expect(m.dailyCalculationLimit, 100);
      expect(m.maxSavedScenarios, 50);
      expect(m.features.comparison, isFalse);
      expect(m.features.priceHistoryMonths, 36);
    });

    test('boş {} payload tüm default değerlere düşer', () {
      final m = AppConfigModel.fromJson(const {});

      expect(m.tier, SubscriptionTier.free);
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
        // tier int — String değil → SubscriptionTier.free (güvenli varsayılan)
        'tier': 42,
      });

      expect(m.tier, SubscriptionTier.free);
      expect(m.dailyCalculationLimit, 20);
      expect(m.maxSavedScenarios, 10);
      expect(m.features.comparison, isTrue);
      expect(m.features.priceHistoryMonths, 12);
    });

    test(
      'bilinmeyen tier string\'i güvenli varsayılan free\'e düşer (F-12-07)',
      () {
        // Backend yeni/bilinmeyen bir plan ("pro") gönderirse uygulama çökmez,
        // free olarak yorumlanır (en kısıtlı/güvenli varsayılan).
        final m = AppConfigModel.fromJson(const {'tier': 'pro'});
        expect(m.tier, SubscriptionTier.free);
      },
    );

    test(
      'tier kanonik-olmayan casing ("Premium"/"PREMIUM") premium\'a normalize edilir (L-4)',
      () {
        // Ödeme yapan kullanıcı, backend casing tutarsızlığında premium'u
        // kaybetmemeli — case-insensitive eşleme.
        expect(
          AppConfigModel.fromJson(const {'tier': 'Premium'}).tier,
          SubscriptionTier.premium,
        );
        expect(
          AppConfigModel.fromJson(const {'tier': 'PREMIUM'}).tier,
          SubscriptionTier.premium,
        );
        expect(
          AppConfigModel.fromJson(const {'tier': 'FREE'}).tier,
          SubscriptionTier.free,
        );
      },
    );

    test(
      'bool flag int 0/1 olarak gelirse tolere edilir (M3: 1→true, 0→false)',
      () {
        final m = AppConfigModel.fromJson(const {
          'features': {'comparison': 1, 'dca': 0},
        });

        // 0/1 artık fail-open default'a düşmüyor; backend int flag'i respeklenir.
        expect(m.features.comparison, isTrue);
        expect(m.features.dca, isFalse);
      },
    );
  });
}
