import 'package:decimal/decimal.dart';

import '../entities/dca_result.dart';
import '../repositories/dca_repository.dart';

class CalculateDca {
  final DcaRepository _repository;
  final DateTime Function() _clock;

  CalculateDca(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<DcaResult> call({
    required String assetSymbol,
    required DateTime startDate,
    DateTime? endDate,
    required Decimal periodicAmount,
    required String period,
    required String amountType,
    bool includeInflation = false,
  }) async {
    final result = await _repository.calculate(
      assetSymbol: assetSymbol,
      startDate: startDate,
      endDate: endDate,
      periodicAmount: periodicAmount,
      period: period,
      amountType: amountType,
      includeInflation: includeInflation,
    );
    return result.withCalculatedAt(_clock());
  }
}
