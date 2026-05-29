import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  // F-08-07: WhatIfBloc ile aynı kanonik guard — DcaSuccess'te formInput
  // zorunlu alanları (startDate/periodicAmount) null olabilir; dil değişimi
  // replay'i bunları null-check eder. Eski kod savedForm.startDate!/
  // periodicAmount! ile crash ederdi.
  group('DcaBloc — DcaLanguageChanged null guard (F-08-07)', () {
    blocTest<DcaBloc, DcaState>(
      'onLanguageChanged_successWithNullFormFields_fallsBackToAssetsLoadedNoCrash',
      build: () => DcaBloc(getAssets, calculateDca),
      setUp: () => when(() => getAssets()).thenAnswer((_) async => [asset]),
      seed: () => DcaSuccess(
        assets: [asset],
        result: fixtureResult(),
        // selectedSymbol dolu ama startDate + periodicAmount null → guard
        formInput: const DcaFormInput(selectedSymbol: 'USDTRY'),
      ),
      act: (bloc) => bloc.add(const DcaLanguageChanged()),
      expect: () => [
        isA<DcaAssetsLoaded>().having(
          (s) => s.formInput.selectedSymbol,
          'selectedSymbol',
          'USDTRY',
        ),
      ],
      // Null-guard'ın amacı: eksik form alanlarında replay (yeniden hesaplama)
      // YAPILMAMALI — calculateDca'ya hiç dokunulmadığını doğrula.
      verify: (_) => verifyZeroInteractions(calculateDca),
    );
  });
}
