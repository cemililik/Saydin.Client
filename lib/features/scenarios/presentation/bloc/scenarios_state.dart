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

  ScenariosLoading({List<SavedScenario> scenarios = const []})
    : scenarios = List.unmodifiable(scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosLoaded extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  ScenariosLoaded(List<SavedScenario> scenarios)
    : scenarios = List.unmodifiable(scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosSaving extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  ScenariosSaving(List<SavedScenario> scenarios)
    : scenarios = List.unmodifiable(scenarios);

  @override
  List<Object?> get props => [scenarios];
}

class ScenariosFailure extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;
  final AppError error;

  ScenariosFailure({
    required List<SavedScenario> scenarios,
    required this.error,
  }) : scenarios = List.unmodifiable(scenarios);

  @override
  List<Object?> get props => [scenarios, error];
}

class ScenariosDuplicate extends ScenariosState {
  @override
  final List<SavedScenario> scenarios;

  ScenariosDuplicate(List<SavedScenario> scenarios)
    : scenarios = List.unmodifiable(scenarios);

  @override
  List<Object?> get props => [scenarios];
}
