import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/entities/subscription_tier.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/config/presentation/widgets/share_result_button.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockAppConfigCubit extends MockCubit<AppConfig>
    implements AppConfigCubit {}

void main() {
  AppConfig config({
    AppConfigReadiness readiness = AppConfigReadiness.ready,
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

  Future<void> pumpButton(
    WidgetTester tester, {
    required AppConfigCubit cubit,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AppConfigCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                ShareResultButton(onPressed: onPressed, enabled: enabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('is absent and cannot invoke its callback when share is off', (
    tester,
  ) async {
    final cubit = _MockAppConfigCubit();
    when(() => cubit.state).thenReturn(config(share: false));
    var invocationCount = 0;

    await pumpButton(tester, cubit: cubit, onPressed: () => invocationCount++);

    expect(find.byIcon(Icons.share_outlined), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(invocationCount, 0);
  });

  testWidgets('is absent while config is not ready', (tester) async {
    final cubit = _MockAppConfigCubit();
    when(
      () => cubit.state,
    ).thenReturn(config(readiness: AppConfigReadiness.loading, share: true));

    await pumpButton(tester, cubit: cubit, onPressed: () {});

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('is absent for fallback even if its local flag is true', (
    tester,
  ) async {
    final cubit = _MockAppConfigCubit();
    when(
      () => cubit.state,
    ).thenReturn(config(readiness: AppConfigReadiness.fallback, share: true));

    await pumpButton(tester, cubit: cubit, onPressed: () {});

    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('keeps enabled share behavior', (tester) async {
    final cubit = _MockAppConfigCubit();
    when(() => cubit.state).thenReturn(config(share: true));
    var invocationCount = 0;

    await pumpButton(tester, cubit: cubit, onPressed: () => invocationCount++);
    await tester.tap(find.byIcon(Icons.share_outlined));

    expect(invocationCount, 1);
  });

  testWidgets('a visible stale button rechecks the flag before callback', (
    tester,
  ) async {
    final cubit = _MockAppConfigCubit();
    var currentConfig = config(share: true);
    when(() => cubit.state).thenAnswer((_) => currentConfig);
    var invocationCount = 0;

    await pumpButton(tester, cubit: cubit, onPressed: () => invocationCount++);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    // Bir rebuild/stream bildirimi olmadan flag'in kapandığı yarış durumunu
    // taklit et: ekrandaki eski buton artık callback'i açamamalı.
    currentConfig = config(share: false);
    await tester.tap(find.byIcon(Icons.share_outlined));

    expect(invocationCount, 0);
  });

  testWidgets('respects a result-level disabled state', (tester) async {
    final cubit = _MockAppConfigCubit();
    when(() => cubit.state).thenReturn(config(share: true));
    var invocationCount = 0;

    await pumpButton(
      tester,
      cubit: cubit,
      enabled: false,
      onPressed: () => invocationCount++,
    );
    await tester.tap(find.byIcon(Icons.share_outlined));

    expect(invocationCount, 0);
  });
}
