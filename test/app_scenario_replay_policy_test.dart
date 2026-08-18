import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/app.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

void main() {
  const allEnabled = AppFeatureFlags(
    comparison: true,
    inflationAdjustment: true,
    share: true,
    dca: true,
    priceHistoryMonths: 12,
  );
  const restricted = AppFeatureFlags(
    comparison: false,
    inflationAdjustment: false,
    share: true,
    dca: false,
    priceHistoryMonths: 12,
  );

  test('replay cannot bypass comparison or DCA feature flags', () {
    expect(
      isScenarioReplayEnabled(ScenarioType.comparison, restricted),
      isFalse,
    );
    expect(isScenarioReplayEnabled(ScenarioType.dca, restricted), isFalse);
    expect(isScenarioReplayEnabled(ScenarioType.whatIf, restricted), isTrue);
    expect(isScenarioReplayEnabled(ScenarioType.portfolio, restricted), isTrue);
    expect(
      isScenarioReplayEnabled(ScenarioType.comparison, allEnabled),
      isTrue,
    );
  });

  test('replay inflation is enabled only by stored bool and current flag', () {
    expect(replayInflationPreference(true, allEnabled), isTrue);
    expect(replayInflationPreference(true, restricted), isFalse);
    expect(replayInflationPreference('true', allEnabled), isFalse);
    expect(replayInflationPreference(null, allEnabled), isFalse);
  });
}
