import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'scenarios_event.dart';
import 'scenarios_state.dart';

class ScenariosBloc extends Bloc<ScenariosEvent, ScenariosState> {
  final GetScenarios _getScenarios;
  final SaveScenario _saveScenario;
  final DeleteScenario _deleteScenario;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  ScenariosBloc(
    this._getScenarios,
    this._saveScenario,
    this._deleteScenario, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter,
       super(const ScenariosInitial()) {
    on<ScenariosRequested>(_onRequested);
    on<ScenarioSaveRequested>(_onSaveRequested);
    on<ScenarioDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onRequested(
    ScenariosRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    emit(ScenariosLoading(scenarios: state.scenarios));
    try {
      final scenarios = await _getScenarios();
      emit(ScenariosLoaded(scenarios));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'get_scenarios');
      }
      emit(ScenariosFailure(scenarios: state.scenarios, error: error));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'get_scenarios');
      emit(
        ScenariosFailure(
          scenarios: state.scenarios,
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  Future<void> _onSaveRequested(
    ScenarioSaveRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    final current = state.scenarios;

    final isDuplicate = current.any(
      (s) =>
          s.assetSymbol == event.assetSymbol &&
          _isSameDay(s.buyDate, event.buyDate) &&
          _isSameDay(s.sellDate, event.sellDate) &&
          s.amount == event.amount &&
          s.amountType == event.amountType,
    );
    if (isDuplicate) {
      emit(ScenariosDuplicate(current));
      return;
    }

    emit(ScenariosSaving(current));
    try {
      final saved = await _saveScenario(
        assetSymbol: event.assetSymbol,
        assetDisplayName: event.assetDisplayName,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        amountType: event.amountType,
      );
      emit(ScenariosLoaded([saved, ...current]));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'save_scenario');
      }
      emit(ScenariosFailure(scenarios: current, error: error));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'save_scenario');
      emit(
        ScenariosFailure(
          scenarios: current,
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  static bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _onDeleteRequested(
    ScenarioDeleteRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    final original = state.scenarios;
    // Optimistic delete: UI'dan hemen kaldır, hata olursa geri yükle
    emit(ScenariosLoaded(original.where((s) => s.id != event.id).toList()));
    try {
      await _deleteScenario(event.id);
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'delete_scenario');
      }
      emit(ScenariosFailure(scenarios: original, error: error));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'delete_scenario');
      emit(
        ScenariosFailure(
          scenarios: original,
          error: UnknownError(cause: e),
        ),
      );
    }
  }
}
