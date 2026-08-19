import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';
import 'package:saydin/features/config/domain/policies/share_policy.dart';

void main() {
  AppConfig config({
    required AppConfigReadiness readiness,
    required bool share,
  }) => AppConfig(
    tier: SubscriptionTier.free,
    dailyCalculationLimit: 20,
    maxSavedScenarios: 10,
    readiness: readiness,
    features: AppFeatureFlags(
      comparison: true,
      inflationAdjustment: true,
      share: share,
      dca: true,
      priceHistoryMonths: 12,
    ),
  );

  group('SharePolicy.canShare', () {
    test('fails closed while config is loading even if the flag is true', () {
      expect(
        SharePolicy.canShare(
          config(readiness: AppConfigReadiness.loading, share: true),
        ),
        isFalse,
      );
    });

    test('uses the remote flag when config is ready', () {
      expect(
        SharePolicy.canShare(
          config(readiness: AppConfigReadiness.ready, share: true),
        ),
        isTrue,
      );
      expect(
        SharePolicy.canShare(
          config(readiness: AppConfigReadiness.ready, share: false),
        ),
        isFalse,
      );
    });

    test('fails closed for fallback regardless of its local flag', () {
      expect(SharePolicy.canShare(AppConfig.defaultConfig), isFalse);
      expect(
        SharePolicy.canShare(
          config(readiness: AppConfigReadiness.fallback, share: false),
        ),
        isFalse,
      );
    });
  });

  group('SharePolicy.runIfAllowed', () {
    test('does not invoke a stale callback after the flag is disabled', () {
      var invocationCount = 0;

      final didRun = SharePolicy.runIfAllowed(
        config(readiness: AppConfigReadiness.ready, share: false),
        () => invocationCount++,
      );

      expect(didRun, isFalse);
      expect(invocationCount, 0);
    });

    test('preserves the enabled callback behavior', () {
      var invocationCount = 0;

      final didRun = SharePolicy.runIfAllowed(
        config(readiness: AppConfigReadiness.ready, share: true),
        () => invocationCount++,
      );

      expect(didRun, isTrue);
      expect(invocationCount, 1);
    });
  });
}
