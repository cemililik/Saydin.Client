import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';

class GetScenarios {
  final ScenariosRepository _repository;

  const GetScenarios(this._repository);

  Future<List<SavedScenario>> call() => _repository.getScenarios();
}
