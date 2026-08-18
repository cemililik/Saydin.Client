import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_reverse_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';

void main() {
  final repository = _FakeWhatIfRepository();
  final clockValue = DateTime(2025, 4, 7, 23, 59);

  test('normal açık uçlu hesap sonucu fake clock snapshotını taşır', () async {
    final result = await CalculateWhatIf(repository, clock: () => clockValue)
        .call(
          assetSymbol: 'USDTRY',
          buyDate: DateTime(2020),
          amount: Decimal.fromInt(100),
          amountType: 'try',
        );

    expect(result.calculatedAt, clockValue);
    expect(result.effectiveSellDate, DateTime(2025, 4, 7));
  });

  test('reverse açık uçlu hesap sonucu fake clock snapshotını taşır', () async {
    final result =
        await CalculateReverseWhatIf(repository, clock: () => clockValue).call(
          assetSymbol: 'USDTRY',
          buyDate: DateTime(2020),
          targetAmount: Decimal.fromInt(200),
          targetAmountType: 'try',
        );

    expect(result.calculatedAt, clockValue);
    expect(result.effectiveSellDate, DateTime(2025, 4, 7));
  });
}

class _FakeWhatIfRepository implements WhatIfRepository {
  @override
  Future<WhatIfResult> calculate({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    bool includeInflation = false,
  }) async => WhatIfResult(
    assetSymbol: assetSymbol,
    assetDisplayName: assetSymbol,
    buyDate: buyDate,
    sellDate: sellDate,
    buyPrice: Decimal.one,
    sellPrice: Decimal.fromInt(2),
    unitsAcquired: Decimal.fromInt(100),
    initialValueTry: amount,
    finalValueTry: Decimal.fromInt(200),
    profitLossTry: Decimal.fromInt(100),
    profitLossPercent: 100,
    isProfit: true,
  );

  @override
  Future<ReverseWhatIfResult> calculateReverse({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal targetAmount,
    required String targetAmountType,
    bool includeInflation = false,
  }) async => ReverseWhatIfResult(
    assetSymbol: assetSymbol,
    assetDisplayName: assetSymbol,
    buyDate: buyDate,
    sellDate: sellDate,
    buyPrice: Decimal.one,
    sellPrice: Decimal.fromInt(2),
    requiredInvestmentTry: Decimal.fromInt(100),
    unitsAcquired: Decimal.fromInt(100),
    targetValueTry: targetAmount,
    profitLossTry: Decimal.fromInt(100),
    profitLossPercent: 100,
    isProfit: true,
  );

  @override
  Future<List<Asset>> getAssets() async => const [];
}
