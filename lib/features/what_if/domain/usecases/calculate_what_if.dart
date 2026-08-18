import 'package:decimal/decimal.dart';

import '../entities/what_if_result.dart';
import '../repositories/what_if_repository.dart';

class CalculateWhatIf {
  final WhatIfRepository _repository;
  final DateTime Function() _clock;

  CalculateWhatIf(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<WhatIfResult> call({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    bool includeInflation = false,
  }) async {
    final result = await _repository.calculate(
      assetSymbol: assetSymbol,
      buyDate: buyDate,
      sellDate: sellDate,
      amount: amount,
      amountType: amountType,
      includeInflation: includeInflation,
    );
    return result.withCalculatedAt(_clock());
  }
}
