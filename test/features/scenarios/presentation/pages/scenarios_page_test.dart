import 'dart:async';
import 'dart:ui' as ui;

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

  testWidgets('visible delete action requires confirmation', (tester) async {
    when(
      () => getScenarios(plan: any(named: 'plan')),
    ).thenAnswer((_) async => [scenario(1)]);
    when(() => deleteScenario(any())).thenAnswer((_) async {});
    final semantics = tester.ensureSemantics();
    await pumpPage(tester);

    final deleteAction = find.byTooltip('Delete');
    expect(deleteAction, findsOneWidget);
    expect(
      tester
          .getSemantics(deleteAction)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    expect(find.text('Delete scenario?'), findsOneWidget);
    verifyNever(() => deleteScenario(any()));

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => deleteScenario(any()));

    await tester.tap(deleteAction);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => deleteScenario('scenario-1')).called(1);
    expect(find.text('Scenario deleted.'), findsOneWidget);
    semantics.dispose();
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
