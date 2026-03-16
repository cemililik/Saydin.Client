import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

abstract class ScenariosState extends Equatable {
  const ScenariosState();

  List<SavedScenario> get scenarios;
}

class ScenariosInitial extends ScenariosState {
  const ScenariosInitial();

  @override
  List<SavedScenario> get scenarios => const [];

  @override
  List<Object?> get props => [];
}

class ScenariosLoading extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  const ScenariosLoading({this.scenarios = const []});

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosLoaded extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  const ScenariosLoaded(this.scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosSaving extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  const ScenariosSaving(this.scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosFailure extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;
  final AppError error;

  const ScenariosFailure({required this.scenarios, required this.error});

  @override
  List<Object?> get props => [scenarios, error];
}
