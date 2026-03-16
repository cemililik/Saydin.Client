import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';

class SaveScenario {
  final ScenariosRepository _repository;

  const SaveScenario(this._repository);

  Future<SavedScenario> call({
    required String assetSymbol,
    required String assetDisplayName,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
  }) => _repository.saveScenario(
    assetSymbol: assetSymbol,
    assetDisplayName: assetDisplayName,
    buyDate: buyDate,
    sellDate: sellDate,
    amount: amount,
    amountType: amountType,
  );
}
