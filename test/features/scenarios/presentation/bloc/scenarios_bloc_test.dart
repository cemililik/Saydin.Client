import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
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

class MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late MockGetScenarios mockGetScenarios;
  late MockSaveScenario mockSaveScenario;
  late MockDeleteScenario mockDeleteScenario;
  late MockErrorReporter reporter;

  setUp(() {
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(ScenarioType.whatIf);
    mockGetScenarios = MockGetScenarios();
    mockSaveScenario = MockSaveScenario();
    mockDeleteScenario = MockDeleteScenario();
    reporter = MockErrorReporter();
  });

  ScenariosBloc buildBloc() =>
      ScenariosBloc(mockGetScenarios, mockSaveScenario, mockDeleteScenario);

  // Dio→AppError eşlemesi artık repository katmanında (F-10-12 deseni); use
  // case'ler BLoC'a doğrudan AppError fırlatır. NoInternetError reporter
  // tetiklemez (yalnızca Unknown/ServerError raporlanır), bu yüzden testler
  // Sentry'ye dokunmadan emit yolunu doğrular.

  void stubSaveAny(SavedScenario result) {
    when(
      () => mockSaveScenario(
        assetSymbol: any(named: 'assetSymbol'),
        assetDisplayName: any(named: 'assetDisplayName'),
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        amount: any(named: 'amount'),
        amountType: any(named: 'amountType'),
        type: any(named: 'type'),
        extraData: any(named: 'extraData'),
      ),
    ).thenAnswer((_) async => result);
  }

  final existingScenario = SavedScenario(
    id: 'abc-123',
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    buyDate: DateTime(2020, 1, 1),
    sellDate: DateTime(2021, 1, 1),
    amount: Decimal.fromInt(10000),
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
            amount: Decimal.fromInt(5000), // farklı miktar
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
            amount: Decimal.fromInt(5000),
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

    blocTest<ScenariosBloc, ScenariosState>(
      'sadece type farklıysa duplicate sayılmaz (type sözleşmesi)',
      build: buildBloc,
      seed: () => ScenariosLoaded([existingScenario]), // type: whatIf (default)
      setUp: () => stubSaveAny(
        SavedScenario(
          id: 'new-id',
          type: ScenarioType.portfolio,
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: Decimal.fromInt(10000),
          amountType: 'try',
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 10000, // aynı tutar ama...
          amountType: 'try',
          type: ScenarioType.portfolio, // ...farklı type → duplicate DEĞİL
        ),
      ),
      expect: () => [isA<ScenariosSaving>(), isA<ScenariosSaved>()],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'save AppError → ScenariosFailure (AppError taşır), liste korunur',
      build: buildBloc,
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
            type: any(named: 'type'),
            extraData: any(named: 'extraData'),
          ),
        ).thenThrow(const NoInternetError());
      },
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'BTC',
          assetDisplayName: 'Bitcoin',
          buyDate: DateTime(2021, 1, 1),
          amount: 5000,
          amountType: 'try',
        ),
      ),
      expect: () => [
        isA<ScenariosSaving>(),
        isA<ScenariosFailure>()
            .having((s) => s.error, 'error', isA<NoInternetError>())
            .having((s) => s.scenarios, 'scenarios', [existingScenario]),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'geçersiz (NaN) tutar Decimal.zero\'a coerce edilmez → yanlış duplicate olmaz',
      build: buildBloc,
      // Tutarı 0 olan, diğer tüm alanları eşleşen mevcut bir senaryo. Eski
      // `?? Decimal.zero` davranışında NaN→0 bununla yanlış-pozitif duplicate
      // yapardı; yeni davranışta NaN→null → duplicate atlanır, kaydetmeye gider.
      seed: () => ScenariosLoaded([
        SavedScenario(
          id: 'zero-amt',
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: Decimal.zero,
          amountType: 'try',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]),
      setUp: () => stubSaveAny(
        SavedScenario(
          id: 'new-id',
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: Decimal.fromInt(5000),
          amountType: 'try',
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount:
              double.nan, // parse edilemez → Decimal.zero'a coerce EDİLMEMELİ
          amountType: 'try',
        ),
      ),
      // Duplicate DEĞİL → kaydetmeye gider (ScenariosDuplicate emit edilmez).
      expect: () => [isA<ScenariosSaving>(), isA<ScenariosSaved>()],
    );
  });

  group('ScenariosBloc — ScenariosRequested', () {
    blocTest<ScenariosBloc, ScenariosState>(
      'başarılı yükleme: Loading → Loaded',
      build: buildBloc,
      setUp: () => when(
        () => mockGetScenarios(plan: any(named: 'plan')),
      ).thenAnswer((_) async => [existingScenario]),
      act: (bloc) => bloc.add(const ScenariosRequested()),
      expect: () => [
        isA<ScenariosLoading>(),
        isA<ScenariosLoaded>().having((s) => s.scenarios, 'scenarios', [
          existingScenario,
        ]),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'AppError → ScenariosFailure(NoInternetError)',
      build: buildBloc,
      setUp: () => when(
        () => mockGetScenarios(plan: any(named: 'plan')),
      ).thenThrow(const NoInternetError()),
      act: (bloc) => bloc.add(const ScenariosRequested()),
      expect: () => [
        isA<ScenariosLoading>(),
        isA<ScenariosFailure>().having(
          (s) => s.error,
          'error',
          isA<NoInternetError>(),
        ),
      ],
    );

    // L-1: FeatureDisabledError beklenen bir iş kuralıdır (paywall), sunucu
    // hatası değil. BLoC raporlama gate'i (yalnız Unknown/Server/Malformed) onu
    // DIŞARIDA bırakır → Sentry'ye gitmemeli. Gate ileride yanlışlıkla
    // denylist'e çevrilir veya FeatureDisabledError allowlist'e eklenirse bu
    // test regresyonu yakalar.
    blocTest<ScenariosBloc, ScenariosState>(
      'FeatureDisabledError Sentry\'ye raporlanMAZ (beklenen iş kuralı)',
      setUp: () {
        registerFallbackValue(StackTrace.empty);
        when(
          () => reporter.report(any(), any(), context: any(named: 'context')),
        ).thenAnswer((_) async {});
        when(
          () => mockGetScenarios(plan: any(named: 'plan')),
        ).thenThrow(const FeatureDisabledError(featureKey: 'extended_history'));
      },
      build: () => ScenariosBloc(
        mockGetScenarios,
        mockSaveScenario,
        mockDeleteScenario,
        reporter: reporter,
      ),
      act: (bloc) => bloc.add(const ScenariosRequested()),
      expect: () => [
        isA<ScenariosLoading>(),
        isA<ScenariosFailure>().having(
          (s) => s.error,
          'error',
          isA<FeatureDisabledError>(),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => reporter.report(any(), any(), context: any(named: 'context')),
        );
      },
    );
  });

  group('ScenariosBloc — ScenarioDeleteRequested', () {
    blocTest<ScenariosBloc, ScenariosState>(
      'başarılı silme: optimistic kaldırma, listeden düşer',
      build: buildBloc,
      seed: () => ScenariosLoaded([existingScenario]),
      setUp: () =>
          when(() => mockDeleteScenario(any())).thenAnswer((_) async {}),
      act: (bloc) => bloc.add(const ScenarioDeleteRequested('abc-123')),
      expect: () => [
        isA<ScenariosLoaded>().having((s) => s.scenarios, 'scenarios', isEmpty),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'silme hatası (5xx/network AppError) → optimistic kaldırma sonra rollback',
      build: buildBloc,
      seed: () => ScenariosLoaded([existingScenario]),
      setUp: () =>
          when(() => mockDeleteScenario(any())).thenThrow(const ServerError()),
      act: (bloc) => bloc.add(const ScenarioDeleteRequested('abc-123')),
      expect: () => [
        // 1) optimistic: hemen listeden kaldır
        isA<ScenariosLoaded>().having((s) => s.scenarios, 'scenarios', isEmpty),
        // 2) hata: original listeyi geri yükleyen Failure
        isA<ScenariosFailure>()
            .having((s) => s.error, 'error', isA<ServerError>())
            .having((s) => s.scenarios, 'scenarios', [existingScenario]),
      ],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'F-11-03 idempotent silme: use case normal dönerse (repo 404\'ü yuttu) '
      'kalem kaldırılmış kalır, Failure YOK',
      build: buildBloc,
      seed: () => ScenariosLoaded([existingScenario]),
      // Idempotency artık repository'de (404 → sessiz başarı); BLoC açısından
      // silme normal tamamlanır. Repo seviyesi 404 davranışı
      // scenarios_repository_impl_test.dart'ta doğrulanır.
      setUp: () =>
          when(() => mockDeleteScenario(any())).thenAnswer((_) async {}),
      act: (bloc) => bloc.add(const ScenarioDeleteRequested('abc-123')),
      expect: () => [
        isA<ScenariosLoaded>().having((s) => s.scenarios, 'scenarios', isEmpty),
      ],
    );
  });

  group('ScenariosBloc — F-11-08 duplicate mode ayrımı', () {
    final reverseScenario = SavedScenario(
      id: 'rev-1',
      assetSymbol: 'USDTRY',
      assetDisplayName: 'Dolar/TL',
      buyDate: DateTime(2020, 1, 1),
      sellDate: DateTime(2021, 1, 1),
      amount: Decimal.fromInt(10000),
      amountType: 'try',
      createdAt: DateTime(2026, 1, 1),
      extraData: const {'mode': 'reverse'},
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'ters senaryo varken aynı alanlı normal senaryo duplicate sayılmaz',
      build: buildBloc,
      seed: () => ScenariosLoaded([reverseScenario]),
      setUp: () => stubSaveAny(
        SavedScenario(
          id: 'new-id',
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: Decimal.fromInt(10000),
          amountType: 'try',
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 10000,
          amountType: 'try',
          // extraData yok → normal mod; reverse'den farklı → duplicate DEĞİL
        ),
      ),
      expect: () => [isA<ScenariosSaving>(), isA<ScenariosSaved>()],
    );

    blocTest<ScenariosBloc, ScenariosState>(
      'aynı mode (reverse) ise duplicate sayılır',
      build: buildBloc,
      seed: () => ScenariosLoaded([reverseScenario]),
      act: (bloc) => bloc.add(
        ScenarioSaveRequested(
          assetSymbol: 'USDTRY',
          assetDisplayName: 'Dolar/TL',
          buyDate: DateTime(2020, 1, 1),
          sellDate: DateTime(2021, 1, 1),
          amount: 10000,
          amountType: 'try',
          extraData: const {'mode': 'reverse'},
        ),
      ),
      expect: () => [isA<ScenariosDuplicate>()],
    );
  });
}
