import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';

class _MockRepository extends Mock implements AppConfigRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late _MockRepository repository;
  late _MockErrorReporter reporter;

  setUpAll(() => registerFallbackValue(StackTrace.empty));

  setUp(() {
    repository = _MockRepository();
    reporter = _MockErrorReporter();
    when(
      () => reporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  const premiumConfig = AppConfig(
    tier: SubscriptionTier.premium,
    dailyCalculationLimit: 0,
    maxSavedScenarios: 0,
    features: AppFeatureFlags(
      comparison: true,
      inflationAdjustment: true,
      share: true,
      dca: true,
      priceHistoryMonths: 0,
    ),
  );

  test('initial state is not ready', () {
    final cubit = AppConfigCubit(repository);
    addTearDown(cubit.close);

    expect(cubit.state, AppConfig.initialConfig);
    expect(cubit.state.isReady, isFalse);
    expect(cubit.state.readiness, AppConfigReadiness.loading);
  });

  blocTest<AppConfigCubit, AppConfig>(
    'load success emits ready backend config',
    setUp: () => when(
      () => repository.getConfig(),
    ).thenAnswer((_) async => premiumConfig),
    build: () => AppConfigCubit(repository, reporter: reporter),
    act: (cubit) => cubit.load(),
    expect: () => [premiumConfig],
  );

  blocTest<AppConfigCubit, AppConfig>(
    'load failure emits ready default fallback and reports',
    setUp: () =>
        when(() => repository.getConfig()).thenThrow(Exception('config down')),
    build: () => AppConfigCubit(repository, reporter: reporter),
    act: (cubit) => cubit.load(),
    expect: () => [AppConfig.defaultConfig],
    verify: (cubit) {
      expect(cubit.state.readiness, AppConfigReadiness.fallback);
      verify(
        () => reporter.report(any(), any(), context: 'app_config_load'),
      ).called(1);
    },
  );
}
