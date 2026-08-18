import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/pages/scenarios_page.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockGetScenarios extends Mock implements GetScenarios {}

class _MockSaveScenario extends Mock implements SaveScenario {}

class _MockDeleteScenario extends Mock implements DeleteScenario {}

class _MockAppConfigRepository extends Mock implements AppConfigRepository {}

void main() {
  late _MockGetScenarios getScenarios;
  late _MockSaveScenario saveScenario;
  late _MockDeleteScenario deleteScenario;
  late AppConfigCubit configCubit;
  late ScenariosBloc scenariosBloc;

  SavedScenario scenario(int index) => SavedScenario(
    id: 'scenario-$index',
    assetSymbol: 'USDTRY',
    assetDisplayName: 'US Dollar $index',
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    amount: Decimal.fromInt(1000 + index),
    amountType: 'try',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() async {
    getScenarios = _MockGetScenarios();
    saveScenario = _MockSaveScenario();
    deleteScenario = _MockDeleteScenario();
    final configRepository = _MockAppConfigRepository();
    when(
      () => configRepository.getConfig(),
    ).thenAnswer((_) async => AppConfig.defaultConfig);
    configCubit = AppConfigCubit(configRepository);
    await configCubit.load();
  });

  tearDown(() async {
    await scenariosBloc.close();
    await configCubit.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    scenariosBloc = ScenariosBloc(getScenarios, saveScenario, deleteScenario);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: configCubit),
          BlocProvider.value(value: scenariosBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ScenariosPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swipe hides immediately and undo restores without DELETE', (
    tester,
  ) async {
    when(
      () => getScenarios(plan: any(named: 'plan')),
    ).thenAnswer((_) async => [scenario(1)]);
    when(() => deleteScenario(any())).thenAnswer((_) async {});
    final semantics = tester.ensureSemantics();
    await pumpPage(tester);

    expect(find.byTooltip('Delete'), findsNothing);
    final deleteSemantics = find.byKey(
      const ValueKey('scenario-delete-semantics-scenario-1'),
    );
    expect(
      tester
          .getSemantics(deleteSemantics)
          .getSemanticsData()
          .customSemanticsActionIds,
      isNotEmpty,
    );

    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('US Dollar 1'), findsNothing);
    expect(
      find.text('Scenario deleted. Tap undo to restore it.'),
      findsOneWidget,
    );
    expect(find.text('Undo (5)'), findsOneWidget);
    verifyNever(() => deleteScenario(any()));

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Undo (4)'), findsOneWidget);
    await tester.tap(find.text('Undo (4)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('US Dollar 1'), findsOneWidget);
    verifyNever(() => deleteScenario(any()));
    semantics.dispose();
  });

  testWidgets('swipe commits DELETE only after the five-second undo window', (
    tester,
  ) async {
    when(
      () => getScenarios(plan: any(named: 'plan')),
    ).thenAnswer((_) async => [scenario(1)]);
    when(() => deleteScenario(any())).thenAnswer((_) async {});
    await pumpPage(tester);

    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    verifyNever(() => deleteScenario(any()));

    await tester.pump(const Duration(seconds: 4));
    verifyNever(() => deleteScenario(any()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => deleteScenario('scenario-1')).called(1);
    expect(find.text('US Dollar 1'), findsNothing);
  });

  testWidgets('pull-to-refresh remains active until its request completes', (
    tester,
  ) async {
    final refreshed = Completer<List<SavedScenario>>();
    var callCount = 0;
    when(() => getScenarios(plan: any(named: 'plan'))).thenAnswer((_) {
      callCount++;
      if (callCount == 1) {
        return Future.value(List.generate(12, scenario));
      }
      return refreshed.future;
    });
    await pumpPage(tester);

    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(callCount, 2);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    refreshed.complete([scenario(99)]);
    await tester.pumpAndSettle();

    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('US Dollar 99'), findsOneWidget);
  });
}
