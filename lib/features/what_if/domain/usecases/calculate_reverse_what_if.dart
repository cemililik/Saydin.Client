import '../entities/reverse_what_if_result.dart';
import '../repositories/what_if_repository.dart';

class CalculateReverseWhatIf {
  final WhatIfRepository _repository;
  CalculateReverseWhatIf(this._repository);

  Future<ReverseWhatIfResult> call({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num targetAmount,
    required String targetAmountType,
    bool includeInflation = false,
  }) => _repository.calculateReverse(
    assetSymbol: assetSymbol,
    buyDate: buyDate,
    sellDate: sellDate,
    targetAmount: targetAmount,
    targetAmountType: targetAmountType,
    includeInflation: includeInflation,
  );
}
