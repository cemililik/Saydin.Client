import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_bloc.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_event.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_state.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';

class MockGetAssets extends Mock implements GetAssets {}

class MockCalculateDca extends Mock implements CalculateDca {}

void main() {
  late MockGetAssets getAssets;
  late MockCalculateDca calculateDca;

  setUp(() {
    getAssets = MockGetAssets();
    calculateDca = MockCalculateDca();
  });

  final asset = Asset(
    symbol: 'USDTRY',
    displayName: 'Dolar/TL',
    category: 'currency',
    firstDate: DateTime.utc(2020, 1, 1),
    lastDate: DateTime.utc(2024, 12, 31),
  );

  DcaResult fixtureResult() => DcaResult(
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    startDate: DateTime.utc(2021, 1, 1),
    endDate: DateTime.utc(2022, 1, 1),
    period: 'monthly',
    periodicAmount: Decimal.fromInt(1000),
    totalPurchases: 12,
    totalInvestedTry: Decimal.fromInt(12000),
    currentValueTry: Decimal.fromInt(15000),
    profitLossTry: Decimal.fromInt(3000),
    profitLossPercent: 25,
    isProfit: true,
    averageCostPerUnit: Decimal.one,
    totalUnitsAcquired: Decimal.fromInt(12000),
    currentUnitPrice: Decimal.fromInt(2),
  );

  // F-08-10: boş varlık listesi DcaEmpty üretir (DcaAssetsLoaded([]) değil) —
  // sayfa açık boş-durum gösterir, çıkmaz boş form değil.
  group('DcaBloc — boş varlık listesi (F-08-10)', () {
    blocTest<DcaBloc, DcaState>(
      'onAssetsRequested_emptyList_emitsDcaEmpty',
      build: () => DcaBloc(getAssets, calculateDca),
      setUp: () => when(() => getAssets()).thenAnswer((_) async => <Asset>[]),
      act: (bloc) => bloc.add(const DcaAssetsRequested()),
      expect: () => [isA<DcaAssetsLoading>(), isA<DcaEmpty>()],
    );

    blocTest<DcaBloc, DcaState>(
      'onAssetsRequested_nonEmptyList_emitsDcaAssetsLoaded',
      build: () => DcaBloc(getAssets, calculateDca),
      setUp: () => when(() => getAssets()).thenAnswer(
        (_) async => [
          Asset(
            symbol: 'USDTRY',
            displayName: 'US Dollar/TL',
            category: 'currency',
            firstDate: asset.firstDate,
            lastDate: asset.lastDate,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const DcaAssetsRequested()),
      expect: () => [isA<DcaAssetsLoading>(), isA<DcaAssetsLoaded>()],
    );
  });

  group('DcaBloc — sonuç snapshot bütünlüğü', () {
    blocTest<DcaBloc, DcaState>(
      'dil değişimi sonucu korur ve yeniden hesaplama yapmaz',
      build: () => DcaBloc(getAssets, calculateDca),
      setUp: () => when(() => getAssets()).thenAnswer(
        (_) async => [
          Asset(
            symbol: 'USDTRY',
            displayName: 'US Dollar/TL',
            category: 'currency',
            firstDate: asset.firstDate,
            lastDate: asset.lastDate,
          ),
        ],
      ),
      seed: () => DcaSuccess(
        assets: [asset],
        result: fixtureResult(),
        // selectedSymbol dolu ama startDate + periodicAmount null → guard
        formInput: const DcaFormInput(selectedSymbol: 'USDTRY'),
      ),
      act: (bloc) => bloc.add(const DcaLanguageChanged()),
      expect: () => [
        isA<DcaSuccess>()
            .having(
              (s) => s.result.currentValueTry,
              'financial result',
              fixtureResult().currentValueTry,
            )
            .having(
              (s) => s.result.assetDisplayName,
              'localized result name',
              'US Dollar/TL',
            )
            .having(
              (s) => s.formInput.selectedSymbol,
              'selectedSymbol',
              'USDTRY',
            ),
      ],
      verify: (_) => verifyZeroInteractions(calculateDca),
    );

    blocTest<DcaBloc, DcaState>(
      'başarılı sonuçtan sonra periyodik tutar değişikliği sonucu temizler',
      build: () => DcaBloc(getAssets, calculateDca),
      seed: () => DcaSuccess(
        assets: [asset],
        result: fixtureResult(),
        formInput: DcaFormInput(
          selectedSymbol: 'USDTRY',
          startDate: DateTime.utc(2021),
          periodicAmount: Decimal.fromInt(100),
        ),
      ),
      act: (bloc) => bloc.add(DcaPeriodicAmountChanged(Decimal.fromInt(200))),
      expect: () => [
        isA<DcaAssetsLoaded>().having(
          (s) => s.formInput.periodicAmount,
          'periodicAmount',
          Decimal.fromInt(200),
        ),
      ],
    );
  });

  group('DcaBloc — nullable ve tarih invariantları', () {
    blocTest<DcaBloc, DcaState>(
      'opsiyonel endDate null ile gerçekten temizlenir',
      build: () => DcaBloc(getAssets, calculateDca),
      seed: () => DcaAssetsLoaded(
        [asset],
        formInput: DcaFormInput(
          selectedSymbol: 'USDTRY',
          startDate: DateTime.utc(2021),
          endDate: DateTime.utc(2022),
        ),
      ),
      act: (bloc) => bloc.add(const DcaEndDateChanged(null)),
      expect: () => [
        isA<DcaAssetsLoaded>().having(
          (state) => state.formInput.endDate,
          'endDate',
          isNull,
        ),
      ],
    );

    blocTest<DcaBloc, DcaState>(
      'sembol değişimi tarihleri yeni asset aralığına atomik clamp eder',
      build: () => DcaBloc(getAssets, calculateDca),
      seed: () => DcaAssetsLoaded(
        [
          asset,
          Asset(
            symbol: 'NEW',
            displayName: 'New',
            category: 'currency',
            firstDate: DateTime.utc(2023, 1, 1),
            lastDate: DateTime.utc(2023, 12, 31),
          ),
        ],
        formInput: DcaFormInput(
          selectedSymbol: 'USDTRY',
          startDate: DateTime.utc(2021),
          endDate: DateTime.utc(2022),
        ),
      ),
      act: (bloc) => bloc.add(const DcaSymbolChanged('NEW')),
      expect: () => [
        isA<DcaAssetsLoaded>()
            .having(
              (state) => state.formInput.startDate,
              'startDate',
              DateTime.utc(2023, 1, 1),
            )
            .having(
              (state) => state.formInput.endDate,
              'endDate',
              DateTime.utc(2023, 1, 1),
            ),
      ],
    );

    blocTest<DcaBloc, DcaState>(
      'ters tarih aralığı domain çağrısına ulaşmaz',
      build: () => DcaBloc(getAssets, calculateDca),
      seed: () => DcaAssetsLoaded([asset]),
      act: (bloc) => bloc.add(
        DcaCalculateRequested(
          assetSymbol: 'USDTRY',
          startDate: DateTime.utc(2022),
          endDate: DateTime.utc(2021),
          periodicAmount: Decimal.fromInt(100),
          period: 'monthly',
        ),
      ),
      expect: () => const <DcaState>[],
      verify: (_) => verifyZeroInteractions(calculateDca),
    );
  });

  blocTest<DcaBloc, DcaState>(
    'replay tanımsız period ile SegmentedButton sözleşmesini atlayamaz',
    build: () => DcaBloc(getAssets, calculateDca),
    seed: () => DcaAssetsLoaded([asset]),
    act: (bloc) => bloc.add(
      DcaReplayRequested(
        assetSymbol: 'USDTRY',
        startDate: DateTime.utc(2021),
        periodicAmount: Decimal.one,
        period: 'daily',
      ),
    ),
    expect: () => [
      isA<DcaFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(calculateDca),
  );

  blocTest<DcaBloc, DcaState>(
    'replay TRY dışı amountType ile TL ekran sözleşmesini atlayamaz',
    build: () => DcaBloc(getAssets, calculateDca),
    seed: () => DcaAssetsLoaded([asset]),
    act: (bloc) => bloc.add(
      DcaReplayRequested(
        assetSymbol: 'USDTRY',
        startDate: DateTime.utc(2021),
        periodicAmount: Decimal.one,
        period: 'monthly',
        amountType: 'units',
      ),
    ),
    expect: () => [
      isA<DcaFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(calculateDca),
  );
}
