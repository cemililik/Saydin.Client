import '../entities/what_if_result.dart';
import '../repositories/what_if_repository.dart';

class CalculateWhatIf {
  final WhatIfRepository _repository;
  CalculateWhatIf(this._repository);

  Future<WhatIfResult> call({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  }) => _repository.calculate(
    assetSymbol: assetSymbol,
    buyDate: buyDate,
    sellDate: sellDate,
    amount: amount,
    amountType: amountType,
    includeInflation: includeInflation,
  );
}
