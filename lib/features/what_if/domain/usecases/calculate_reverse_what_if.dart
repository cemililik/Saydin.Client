import 'package:decimal/decimal.dart';

import '../entities/reverse_what_if_result.dart';
import '../repositories/what_if_repository.dart';

class CalculateReverseWhatIf {
  final WhatIfRepository _repository;
  final DateTime Function() _clock;

  CalculateReverseWhatIf(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<ReverseWhatIfResult> call({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal targetAmount,
    required String targetAmountType,
    bool includeInflation = false,
  }) async {
    final result = await _repository.calculateReverse(
      assetSymbol: assetSymbol,
      buyDate: buyDate,
      sellDate: sellDate,
      targetAmount: targetAmount,
      targetAmountType: targetAmountType,
      includeInflation: includeInflation,
    );
    return result.withCalculatedAt(_clock());
  }
}
