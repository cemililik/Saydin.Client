import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_reverse_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';

class MockGetAssets extends Mock implements GetAssets {}

class MockCalculateWhatIf extends Mock implements CalculateWhatIf {}

class MockCalculateReverseWhatIf extends Mock
    implements CalculateReverseWhatIf {}

void main() {
  setUpAll(() => registerFallbackValue(Decimal.zero));

  late MockGetAssets mockGetAssets;
  late MockCalculateWhatIf mockCalculateWhatIf;
  late MockCalculateReverseWhatIf mockCalculateReverseWhatIf;

  setUp(() {
    mockGetAssets = MockGetAssets();
    mockCalculateWhatIf = MockCalculateWhatIf();
    mockCalculateReverseWhatIf = MockCalculateReverseWhatIf();
  });

  final assetWithRange = Asset(
    symbol: 'USDTRY',
    displayName: 'Dolar/TL',
    category: 'currency',
    firstDate: DateTime.utc(2020, 1, 1),
    lastDate: DateTime.utc(2024, 12, 31),
  );

  group('WhatIfBloc — WhatIfSymbolChanged', () {
    blocTest<WhatIfBloc, WhatIfState>(
      'tarihleri sıkıştırır ve dateAdjusted=true set eder',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded(
        [assetWithRange],
        formInput: WhatIfFormInput(
          selectedSymbol: 'BTC',
          buyDate: DateTime.utc(2015, 1, 1), // firstDate öncesi
          sellDate: DateTime.utc(2025, 6, 1), // lastDate sonrası
          amountType: 'try',
        ),
      ),
      act: (bloc) => bloc.add(const WhatIfSymbolChanged('USDTRY')),
      expect: () => [
        isA<WhatIfAssetsLoaded>()
            .having((s) => s.formInput.dateAdjusted, 'dateAdjusted', isTrue)
            .having(
              (s) => s.formInput.buyDate,
              'buyDate',
              DateTime.utc(2020, 1, 1),
            )
            .having(
              (s) => s.formInput.sellDate,
              'sellDate',
              DateTime.utc(2024, 12, 31),
            ),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'tarihler aralık içindeyse dateAdjusted=false kalır',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded(
        [assetWithRange],
        formInput: WhatIfFormInput(
          selectedSymbol: 'BTC',
          buyDate: DateTime.utc(2021, 1, 1), // aralık içi
          sellDate: DateTime.utc(2022, 6, 1), // aralık içi
          amountType: 'try',
        ),
      ),
      act: (bloc) => bloc.add(const WhatIfSymbolChanged('USDTRY')),
      expect: () => [
        isA<WhatIfAssetsLoaded>().having(
          (s) => s.formInput.dateAdjusted,
          'dateAdjusted',
          isFalse,
        ),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'tarihler null ise dateAdjusted=false kalır',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded(
        [assetWithRange],
        formInput: const WhatIfFormInput(
          selectedSymbol: 'BTC',
          amountType: 'try',
          // buyDate ve sellDate null
        ),
      ),
      act: (bloc) => bloc.add(const WhatIfSymbolChanged('USDTRY')),
      expect: () => [
        isA<WhatIfAssetsLoaded>().having(
          (s) => s.formInput.dateAdjusted,
          'dateAdjusted',
          isFalse,
        ),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'yeni asset desteklemiyorsa amountType try\'ye sıfırlanır',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded(
        [assetWithRange],
        formInput: const WhatIfFormInput(
          selectedSymbol: 'XAUTRY',
          amountType: 'grams', // currency desteklemiyor
        ),
      ),
      act: (bloc) => bloc.add(const WhatIfSymbolChanged('USDTRY')),
      expect: () => [
        isA<WhatIfAssetsLoaded>().having(
          (s) => s.formInput.amountType,
          'amountType',
          'try',
        ),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'sembol state\'e yazılır',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded([assetWithRange]),
      act: (bloc) => bloc.add(const WhatIfSymbolChanged('USDTRY')),
      expect: () => [
        isA<WhatIfAssetsLoaded>().having(
          (s) => s.formInput.selectedSymbol,
          'selectedSymbol',
          'USDTRY',
        ),
      ],
    );
  });

  group('WhatIfBloc — sonuç snapshot bütünlüğü', () {
    WhatIfResult fixtureResult() => WhatIfResult(
      assetSymbol: 'USDTRY',
      assetDisplayName: 'Dolar/TL',
      buyDate: DateTime.utc(2021, 1, 1),
      sellDate: DateTime.utc(2022, 1, 1),
      buyPrice: Decimal.one,
      sellPrice: Decimal.fromInt(2),
      unitsAcquired: Decimal.fromInt(100),
      initialValueTry: Decimal.fromInt(100),
      finalValueTry: Decimal.fromInt(200),
      profitLossTry: Decimal.fromInt(100),
      profitLossPercent: 100,
      isProfit: true,
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'dil değişimi sonucu korur ve yeniden hesaplama yapmaz',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      setUp: () => when(() => mockGetAssets()).thenAnswer(
        (_) async => [
          Asset(
            symbol: 'USDTRY',
            displayName: 'US Dollar/TL',
            category: 'currency',
            firstDate: assetWithRange.firstDate,
            lastDate: assetWithRange.lastDate,
          ),
        ],
      ),
      seed: () => WhatIfSuccess(
        assets: [assetWithRange],
        result: fixtureResult(),
        // selectedSymbol dolu ama buyDate + amount null → guard tetiklenir
        formInput: const WhatIfFormInput(
          selectedSymbol: 'USDTRY',
          amountType: 'try',
        ),
      ),
      act: (bloc) => bloc.add(const WhatIfLanguageChanged()),
      expect: () => [
        isA<WhatIfSuccess>()
            .having(
              (s) => s.result?.finalValueTry,
              'financial result',
              fixtureResult().finalValueTry,
            )
            .having(
              (s) => s.result?.assetDisplayName,
              'localized result name',
              'US Dollar/TL',
            )
            .having(
              (s) => s.formInput.selectedSymbol,
              'selectedSymbol',
              'USDTRY',
            ),
      ],
      verify: (_) {
        verifyNever(
          () => mockCalculateWhatIf.call(
            assetSymbol: any(named: 'assetSymbol'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            amount: any(named: 'amount'),
            amountType: any(named: 'amountType'),
            includeInflation: any(named: 'includeInflation'),
          ),
        );
        verifyZeroInteractions(mockCalculateReverseWhatIf);
      },
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'başarılı sonuçtan sonra tutar değişikliği sonucu geçersiz kılar',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfSuccess(
        assets: [assetWithRange],
        result: fixtureResult(),
        formInput: WhatIfFormInput(
          selectedSymbol: 'USDTRY',
          buyDate: DateTime.utc(2021),
          amount: Decimal.fromInt(100),
        ),
      ),
      act: (bloc) => bloc.add(WhatIfAmountChanged(Decimal.fromInt(200))),
      expect: () => [
        isA<WhatIfAssetsLoaded>().having(
          (s) => s.formInput.amount,
          'amount',
          Decimal.fromInt(200),
        ),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'alış tarihi satıştan ileri taşınırsa satış tarihi atomik temizlenir',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      seed: () => WhatIfAssetsLoaded(
        [assetWithRange],
        formInput: WhatIfFormInput(
          selectedSymbol: 'USDTRY',
          buyDate: DateTime.utc(2021),
          sellDate: DateTime.utc(2022),
        ),
      ),
      act: (bloc) => bloc.add(WhatIfBuyDateChanged(DateTime.utc(2023))),
      expect: () => [
        isA<WhatIfAssetsLoaded>()
            .having(
              (state) => state.formInput.buyDate,
              'buyDate',
              DateTime.utc(2023),
            )
            .having((state) => state.formInput.sellDate, 'sellDate', isNull),
      ],
    );

    blocTest<WhatIfBloc, WhatIfState>(
      'hesap sürerken form değişirse eski cevap yayınlanmaz',
      build: () => WhatIfBloc(
        mockGetAssets,
        mockCalculateWhatIf,
        mockCalculateReverseWhatIf,
      ),
      setUp: () {
        final completer = Completer<WhatIfResult>();
        calculationCompleter = completer;
        when(
          () => mockCalculateWhatIf(
            assetSymbol: any(named: 'assetSymbol'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            amount: any(named: 'amount'),
            amountType: any(named: 'amountType'),
            includeInflation: any(named: 'includeInflation'),
          ),
        ).thenAnswer((_) => completer.future);
      },
      seed: () => WhatIfAssetsLoaded([assetWithRange]),
      act: (bloc) async {
        bloc.add(
          WhatIfCalculateRequested(
            assetSymbol: 'USDTRY',
            buyDate: DateTime.utc(2021),
            amount: Decimal.fromInt(100),
            amountType: 'try',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(WhatIfAmountChanged(Decimal.fromInt(200)));
        await Future<void>.delayed(Duration.zero);
        calculationCompleter.complete(fixtureResult());
      },
      expect: () => [
        isA<WhatIfCalculating>(),
        isA<WhatIfAssetsLoaded>().having(
          (state) => state.formInput.amount,
          'edited amount',
          Decimal.fromInt(200),
        ),
      ],
    );
  });

  blocTest<WhatIfBloc, WhatIfState>(
    'reverse replay units tutarıyla normal form invariantını atlayamaz',
    build: () => WhatIfBloc(
      mockGetAssets,
      mockCalculateWhatIf,
      mockCalculateReverseWhatIf,
    ),
    seed: () => WhatIfAssetsLoaded([assetWithRange]),
    act: (bloc) => bloc.add(
      WhatIfReplayRequested(
        assetSymbol: 'USDTRY',
        buyDate: DateTime.utc(2021),
        amount: Decimal.one,
        amountType: 'units',
        calculationMode: CalculationMode.reverse,
      ),
    ),
    expect: () => [
      isA<WhatIfFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(mockCalculateReverseWhatIf),
  );
}

late Completer<WhatIfResult> calculationCompleter;
