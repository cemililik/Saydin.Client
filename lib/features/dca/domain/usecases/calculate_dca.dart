import '../entities/dca_result.dart';
import '../repositories/dca_repository.dart';

class CalculateDca {
  final DcaRepository _repository;
  CalculateDca(this._repository);

  Future<DcaResult> call({
    required String assetSymbol,
    required DateTime startDate,
    DateTime? endDate,
    required num periodicAmount,
    required String period,
    required String amountType,
    bool includeInflation = false,
  }) => _repository.calculate(
    assetSymbol: assetSymbol,
    startDate: startDate,
    endDate: endDate,
    periodicAmount: periodicAmount,
    period: period,
    amountType: amountType,
    includeInflation: includeInflation,
  );
}
