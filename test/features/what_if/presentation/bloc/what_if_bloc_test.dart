import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
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
}
