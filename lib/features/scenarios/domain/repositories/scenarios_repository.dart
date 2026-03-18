import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

abstract class ScenariosRepository {
  Future<List<SavedScenario>> getScenarios({String plan = 'free'});

  Future<SavedScenario> saveScenario({
    required String assetSymbol,
    required String assetDisplayName,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    ScenarioType type = ScenarioType.whatIf,
    Map<String, dynamic>? extraData,
  });

  Future<void> deleteScenario(String id);
}
