import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/utils/money_parser.dart';
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
      final scenarios = await _getScenarios(plan: event.plan);
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

    // `s.amount` Decimal, `event.amount` num (form input). Daha önce
    // `.toDouble()` üzerinden double `==` karşılaştırması vardı; bu
    // IEEE-754 precision farkını sızdırma riski taşıyordu (ve Decimal
    // sözleşmesiyle çelişiyordu). Event tutarını Decimal'a çevirip
    // Decimal `==` ile karşılaştır — Decimal equality exact.
    //
    // `MoneyParser.tryDecimal` ham `Decimal.parse` yerine kullanılır: num
    // NaN/Infinity'de null döner (ham `Decimal.parse` `FormatException` atıp
    // try bloğu dışında crash ederdi). null'ı `Decimal.zero`'a COERCE ETME —
    // geçersiz tutarı 0 gibi göstermek, amount'u 0 olan bir senaryoyla
    // yanlış-pozitif duplicate eşleşmesi yaratır. Parse edilemiyorsa duplicate
    // kontrolünü tümden atla (kaydetme akışı geçersiz tutarı kendi yakalar);
    // geçerli parse'ta Decimal `==` ile exact karşılaştır.
    final eventAmountDecimal = MoneyParser.tryDecimal(event.amount);
    // F-11-08: normal ('what_if') ve ters ('reverse') hesaplama aynı
    // type=whatIf taşır; ayrım extraData['mode']'da. Mode duplicate anahtarına
    // dahil edilmezse aynı asset+tarih+tutarlı bir normal ve bir ters senaryo
    // çakışır ve ikincisi kaydedilemez.
    final eventMode = event.extraData?['mode'] as String?;
    final isDuplicate =
        eventAmountDecimal != null &&
        current.any(
          (s) =>
              s.type == event.type &&
              s.assetSymbol == event.assetSymbol &&
              _isSameDay(s.buyDate, event.buyDate) &&
              _isSameDay(s.sellDate, event.sellDate) &&
              s.amount == eventAmountDecimal &&
              s.amountType == event.amountType &&
              (s.extraData?['mode'] as String?) == eventMode,
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
      // F-11-03: silme idempotent olmalı. 404 = kaynak zaten yok (sunucuda
      // silinmiş / çift dokunuş) = istenen son durum → optimistic kaldırmayı
      // koru, hata GÖSTERME, raporlama. (DioErrorMapper 404'ü
      // PriceNotFoundError'a indirgediği için mapper yerine ham status'e bak.)
      if (e.response?.statusCode == 404) return;
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'delete_scenario');
      }
      // 5xx / network: optimistic kaldırmayı geri al (original'i taşıyan Failure).
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
