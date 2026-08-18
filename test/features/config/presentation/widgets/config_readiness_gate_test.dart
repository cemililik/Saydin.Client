import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/app.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/config/presentation/widgets/config_readiness_gate.dart';
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:saydin/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockRepository extends Mock implements AppConfigRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

class _MockOnboardingCubit extends MockCubit<OnboardingStatus>
    implements OnboardingCubit {}

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

  Future<void> pumpGate(WidgetTester tester, AppConfigCubit cubit) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const ConfigReadinessGate(child: Text('config-ready-child')),
        ),
      ),
    );
  }

  testWidgets('hides plan-dependent child until remote config is ready', (
    tester,
  ) async {
    final pendingConfig = Completer<AppConfig>();
    when(() => repository.getConfig()).thenAnswer((_) => pendingConfig.future);
    final cubit = AppConfigCubit(repository, reporter: reporter);
    addTearDown(cubit.close);

    await pumpGate(tester, cubit);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('config-ready-child'), findsNothing);
    verify(() => repository.getConfig()).called(1);

    pendingConfig.complete(premiumConfig);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('config-ready-child'), findsOneWidget);
  });

  testWidgets('unblocks the app with a safe fallback after config failure', (
    tester,
  ) async {
    when(() => repository.getConfig()).thenThrow(Exception('config down'));
    final cubit = AppConfigCubit(repository, reporter: reporter);
    addTearDown(cubit.close);

    await pumpGate(tester, cubit);
    await tester.pump();

    expect(cubit.state.usesFallback, isTrue);
    expect(find.text('config-ready-child'), findsOneWidget);
    verify(() => repository.getConfig()).called(1);
  });

  testWidgets('pending legal notice does not start config network load', (
    tester,
  ) async {
    when(() => repository.getConfig()).thenAnswer((_) async => premiumConfig);
    final configCubit = AppConfigCubit(repository, reporter: reporter);
    final onboardingCubit = _MockOnboardingCubit();
    when(() => onboardingCubit.state).thenReturn(OnboardingStatus.pending);
    whenListen(
      onboardingCubit,
      const Stream<OnboardingStatus>.empty(),
      initialState: OnboardingStatus.pending,
    );
    addTearDown(configCubit.close);
    addTearDown(onboardingCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AppConfigCubit>.value(value: configCubit),
          BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppHome(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(ConfigReadinessGate), findsNothing);
    verifyNever(() => repository.getConfig());

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
