import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';

class DeleteScenario {
  final ScenariosRepository _repository;

  const DeleteScenario(this._repository);

  Future<void> call(String id) => _repository.deleteScenario(id);
}
