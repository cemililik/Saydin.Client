import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_state.dart';

class MockGetScenarios extends Mock implements GetScenarios {}

class MockSaveScenario extends Mock implements SaveScenario {}

class MockDeleteScenario extends Mock implements DeleteScenario {}

void main() {
  late MockGetScenarios mockGetScenarios;
  late MockSaveScenario mockSaveScenario;
  late MockDeleteScenario mockDeleteScenario;

  setUp(() {
    registerFallbackValue(DateTime(2020));
    mockGetScenarios = MockGetScenarios();
    mockSaveScenario = MockSaveScenario();
    mockDeleteScenario = MockDeleteScenario();
  });

  final existingScenario = SavedScenario(
    id: 'abc-123',
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    amount: 10000,
    amountType: 'try',
    createdAt: DateTime(2026, 1, 1),
  );

  group('ScenariosBloc — ScenarioSaveRequested', () {
    blocTest<ScenariosBloc, ScenariosState>(
      'aynı senaryo varsa ScenariosDuplicate emit edilir ve API çağrılmaz',
      build: () =>
          ScenariosBloc(mockGetScenarios, mockSaveScenario, mockDeleteScenario),
      seed: () => ScenariosLoaded([existingScenario]),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 10000,
          amountType: 'try',
        ),
      ),
      expect: () => [isA<ScenariosDuplicate>()],
      verify: (_) {
        verifyNever(
          () => mockSaveScenario(
            assetSymbol: any(named: 'assetSymbol'),
            assetDisplayName: any(named: 'assetDisplayName'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            amount: any(named: 'amount'),
            amountType: any(named: 'amountType'),
          ),
        );
      },
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'ScenariosDuplicate mevcut senaryoları korur',
      build: () =>
          ScenariosBloc(mockGetScenarios, mockSaveScenario, mockDeleteScenario),
      seed: () => ScenariosLoaded([existingScenario]),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 10000,
          amountType: 'try',
        ),
      ),
      expect: () => [
        isA<ScenariosDuplicate>().having((s) => s.scenarios, 'scenarios', [
          existingScenario,
        ]),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'miktar farklıysa duplicate sayılmaz',
      build: () =>
          ScenariosBloc(mockGetScenarios, mockSaveScenario, mockDeleteScenario),
      seed: () => ScenariosLoaded([existingScenario]),
      setUp: () {
        when(
          () => mockSaveScenario(
            assetSymbol: any(named: 'assetSymbol'),
            assetDisplayName: any(named: 'assetDisplayName'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            amount: any(named: 'amount'),
            amountType: any(named: 'amountType'),
          ),
        ).thenAnswer(
          (_) async => SavedScenario(
            id: 'new-id',
            assetSymbol: 'USDTRY',
            assetDisplayName: 'Dolar/TL',
            buyDate: DateTime(2020, 1, 1),
            sellDate: DateTime(2021, 1, 1),
            amount: 5000, // farklı miktar
            amountType: 'try',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
      },
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 5000, // farklı miktar → duplicate değil
          amountType: 'try',
        ),
      ),
      expect: () => [
        isA<ScenariosSaving>(),
        isA<ScenariosSaved>().having(
          (s) => s.scenarios,
          'scenarios',
          hasLength(2),
        ),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'benzersiz senaryo kaydedilince liste büyür',
      build: () =>
          ScenariosBloc(mockGetScenarios, mockSaveScenario, mockDeleteScenario),
      seed: () => ScenariosLoaded([existingScenario]),
      setUp: () {
        when(
          () => mockSaveScenario(
            assetSymbol: any(named: 'assetSymbol'),
            assetDisplayName: any(named: 'assetDisplayName'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            amount: any(named: 'amount'),
            amountType: any(named: 'amountType'),
          ),
        ).thenAnswer(
          (_) async => SavedScenario(
            id: 'new-id',
            assetSymbol: 'BTC',
            assetDisplayName: 'Bitcoin',
            buyDate: DateTime(2021, 1, 1),
            amount: 5000,
            amountType: 'try',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
      },
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'BTC', // farklı sembol → duplicate değil
          assetDisplayName: 'Bitcoin',
          buyDate: DateTime(2021, 1, 1),
          amount: 5000,
          amountType: 'try',
        ),
      ),
      expect: () => [
        isA<ScenariosSaving>(),
        isA<ScenariosSaved>().having(
          (s) => s.scenarios,
          'scenarios',
          hasLength(2),
        ),
      ],
    );
  });
}
