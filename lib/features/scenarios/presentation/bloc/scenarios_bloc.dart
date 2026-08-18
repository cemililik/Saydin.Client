import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/scenario_input_fingerprint.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'scenarios_event.dart';
import 'scenarios_state.dart';

/// `bloc_concurrency` paketindeki `sequential()` ile aynı davranış: aynı event
/// tipinin handler'larını sırayla çalıştırır. Paket doğrudan bağımlılık olmadığı
/// için küçük transformer burada tutulur.
EventTransformer<E> _sequential<E>() =>
    (events, mapper) => events.asyncExpand(mapper);

class ScenariosBloc extends Bloc<ScenariosEvent, ScenariosState> {
  final GetScenarios _getScenarios;
  final SaveScenario _saveScenario;
  final DeleteScenario _deleteScenario;
  final ErrorReporter _reporter;

  ScenariosBloc(
    this._getScenarios,
    this._saveScenario,
    this._deleteScenario, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter,
       super(const ScenariosInitial()) {
    on<ScenariosRequested>(_onRequested);
    on<ScenarioSaveRequested>(_onSaveRequested, transformer: _sequential());
    on<ScenarioDeleteRequested>(_onDeleteRequested, transformer: _sequential());
  }

  Future<void> _onRequested(
    ScenariosRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    emit(ScenariosLoading(scenarios: state.scenarios));
    try {
      final scenarios = await _getScenarios(plan: event.plan);
      emit(ScenariosLoaded(scenarios));
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'get_scenarios');
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
    } finally {
      final completion = event.completion;
      if (completion != null && !completion.isCompleted) {
        completion.complete();
      }
    }
  }

  Future<void> _onSaveRequested(
    ScenarioSaveRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    final current = state.scenarios;

    // Ortak alanlara ek olarak her hesap türünün gerçek girdilerini kapsayan
    // canonical fingerprint kullanılır. Böylece DCA periodu, enflasyon seçimi
    // ve portföy dağılımı gibi farklı hesaplar yanlış duplicate sayılmaz;
    // winner/totalReturn/displayName gibi sonuç alanları anahtara sızmaz.
    final eventFingerprint = ScenarioInputFingerprint.fromValues(
      type: event.type,
      assetSymbol: event.assetSymbol,
      buyDate: event.buyDate,
      sellDate: event.sellDate,
      amount: event.amount,
      amountType: event.amountType,
      extraData: event.extraData,
    );
    final isDuplicate = current.any(
      (scenario) =>
          ScenarioInputFingerprint.fromScenario(scenario) == eventFingerprint,
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
        type: event.type,
        extraData: event.extraData,
      );
      emit(ScenariosSaved([saved, ...current]));
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'save_scenario');
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

  Future<void> _onDeleteRequested(
    ScenarioDeleteRequested event,
    Emitter<ScenariosState> emit,
  ) async {
    final original = state.scenarios;
    // Optimistic delete: UI'dan hemen kaldır, hata olursa geri yükle
    emit(ScenariosLoaded(original.where((s) => s.id != event.id).toList()));
    try {
      await _deleteScenario(event.id);
      if (event.completion case final completion?
          when !completion.isCompleted) {
        completion.complete(true);
      }
    } on AppError catch (error, st) {
      // F-11-03 idempotency (404 = zaten yok → sessiz başarı) repository
      // katmanına taşındı; burada yalnızca gerçek hatalar (5xx/network) görülür.
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'delete_scenario');
      }
      // 5xx / network: optimistic kaldırmayı geri al (original'i taşıyan Failure).
      emit(ScenariosFailure(scenarios: original, error: error));
      if (event.completion case final completion?
          when !completion.isCompleted) {
        completion.complete(false);
      }
    } catch (e, st) {
      await _reporter.report(e, st, context: 'delete_scenario');
      emit(
        ScenariosFailure(
          scenarios: original,
          error: UnknownError(cause: e),
        ),
      );
      if (event.completion case final completion?
          when !completion.isCompleted) {
        completion.complete(false);
      }
    }
  }
}
