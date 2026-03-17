import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

abstract class ScenariosRepository {
  Future<List<SavedScenario>> getScenarios();

  Future<SavedScenario> saveScenario({
    required String assetSymbol,
    required String assetDisplayName,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
  });

  Future<void> deleteScenario(String id);
}
