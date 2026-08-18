import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'dca_event.dart';
import 'dca_state.dart';

class DcaBloc extends Bloc<DcaEvent, DcaState> {
  final GetAssets _getAssets;
  final CalculateDca _calculateDca;
  final ErrorReporter _reporter;
  int _requestSeq = 0;

  void _invalidateInflightRequests() => _requestSeq++;

  DcaBloc(
    this._getAssets,
    this._calculateDca, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter,
       super(const DcaInitial()) {
    on<DcaAssetsRequested>(_onAssetsRequested);
    on<DcaSymbolChanged>(_onSymbolChanged);
    on<DcaStartDateChanged>(_onStartDateChanged);
    on<DcaEndDateChanged>(_onEndDateChanged);
    on<DcaPeriodChanged>(_onPeriodChanged);
    on<DcaPeriodicAmountChanged>(_onPeriodicAmountChanged);
    on<DcaInflationToggled>(_onInflationToggled);
    on<DcaCalculateRequested>(_onCalculateRequested);
    on<DcaReplayRequested>(_onReplayRequested);
    on<DcaLanguageChanged>(_onLanguageChanged);
  }

  DcaFormInput get _formInput => state.formInput;

  List<Asset> _currentAssets() => switch (state) {
    DcaAssetsLoaded(:final assets) => assets,
    DcaSuccess(:final assets) => assets,
    DcaFailure(:final assets) => assets,
    DcaCalculating(:final assets) => assets,
    _ => <Asset>[],
  };

  Future<void> _onAssetsRequested(
    DcaAssetsRequested event,
    Emitter<DcaState> emit,
  ) async {
    emit(const DcaAssetsLoading());
    try {
      final assets = await _getAssets();
      // F-08-10: boş liste → DcaEmpty (sonsuz/çıkmaz boş form yerine açık
      // boş-durum + tekrar dene). Boş olmayan liste normal akışa devam eder.
      if (assets.isEmpty) {
        emit(DcaEmpty(formInput: _formInput));
      } else {
        emit(DcaAssetsLoaded(assets, formInput: _formInput));
      }
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'dca_get_assets');
      }
      emit(DcaFailure(assets: const [], error: error, formInput: _formInput));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'dca_get_assets');
      emit(
        DcaFailure(
          assets: const [],
          error: UnknownError(cause: e),
          formInput: _formInput,
        ),
      );
    }
  }

  void _onSymbolChanged(DcaSymbolChanged event, Emitter<DcaState> emit) {
    final asset = _currentAssets()
        .where((candidate) => candidate.symbol == event.symbol)
        .firstOrNull;
    if (asset == null) {
      _emitWithUpdatedForm(
        emit,
        _formInput.copyWith(selectedSymbol: event.symbol),
      );
      return;
    }
    final range = assetDateRange(
      assetFirstDate: asset.firstDate,
      assetLastDate: asset.lastDate,
      priceHistoryMonths: 0,
    );
    final startDate = _clampDate(_formInput.startDate, range);
    var endDate = _clampDate(_formInput.endDate, range);
    if (startDate != null && !isValidFinancialDateRange(startDate, endDate)) {
      endDate = null;
    }
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(
        selectedSymbol: event.symbol,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  DateTime? _clampDate(
    DateTime? value,
    ({DateTime? firstDate, DateTime? lastDate}) range,
  ) {
    if (value == null) return null;
    final first = range.firstDate;
    final last = range.lastDate;
    if (first != null && value.isBefore(first)) return first;
    if (last != null && value.isAfter(last)) return last;
    return value;
  }

  void _onStartDateChanged(DcaStartDateChanged event, Emitter<DcaState> emit) {
    final endDate = isValidFinancialDateRange(event.date, _formInput.endDate)
        ? _formInput.endDate
        : null;
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(startDate: event.date, endDate: endDate),
    );
  }

  void _onEndDateChanged(DcaEndDateChanged event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(endDate: event.date));
  }

  void _onPeriodChanged(DcaPeriodChanged event, Emitter<DcaState> emit) {
    if (!_validPeriods.contains(event.period)) return;
    _emitWithUpdatedForm(emit, _formInput.copyWith(period: event.period));
  }

  void _onPeriodicAmountChanged(
    DcaPeriodicAmountChanged event,
    Emitter<DcaState> emit,
  ) {
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(periodicAmount: event.amount),
    );
  }

  void _onInflationToggled(DcaInflationToggled event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(includeInflation: !_formInput.includeInflation),
    );
  }

  void _emitWithUpdatedForm(Emitter<DcaState> emit, DcaFormInput updated) {
    final current = state;
    if (current is DcaAssetsLoaded) {
      emit(current.copyWith(formInput: updated));
    } else if (current is DcaSuccess || current is DcaCalculating) {
      // Form değiştiğinde önceki hesap ve aksiyonlar artık geçerli değildir.
      _invalidateInflightRequests();
      emit(DcaAssetsLoaded(_currentAssets(), formInput: updated));
    } else if (current is DcaFailure) {
      emit(current.copyWith(formInput: updated));
    }
  }

  Future<void> _onCalculateRequested(
    DcaCalculateRequested event,
    Emitter<DcaState> emit,
  ) async {
    final currentAssets = _currentAssets();
    final asset = currentAssets
        .where((candidate) => candidate.symbol == event.assetSymbol)
        .firstOrNull;
    if (asset == null ||
        event.amountType != 'try' ||
        !_validPeriods.contains(event.period) ||
        !_datesAreValidForAsset(event.startDate, event.endDate, asset) ||
        !FinancialAmountValidator.isValid(
          value: event.periodicAmount,
          amountType: event.amountType,
          allowedAmountTypes: asset.allowedAmountTypes,
        )) {
      return;
    }

    await _reporter.recordAction(
      'dca.calculated',
      category: 'dca',
      data: const {'feature': 'dca', 'action': 'calculated'},
    );

    final updatedForm = _formInput.copyWith(
      selectedSymbol: event.assetSymbol,
      startDate: event.startDate,
      endDate: event.endDate,
      periodicAmount: event.periodicAmount,
      period: event.period,
      amountType: event.amountType,
      includeInflation: event.includeInflation,
    );
    final requestSeq = ++_requestSeq;
    emit(DcaCalculating(currentAssets, formInput: updatedForm));
    try {
      final result = await _calculateDca(
        assetSymbol: event.assetSymbol,
        startDate: event.startDate,
        endDate: event.endDate,
        periodicAmount: event.periodicAmount,
        period: event.period,
        amountType: event.amountType,
        includeInflation: event.includeInflation,
      );
      if (requestSeq != _requestSeq) return;
      emit(
        DcaSuccess(
          assets: currentAssets,
          result: result,
          formInput: updatedForm,
        ),
      );
    } on AppError catch (error, st) {
      if (requestSeq != _requestSeq) return;
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'dca_calculate');
      }
      emit(
        DcaFailure(assets: currentAssets, error: error, formInput: updatedForm),
      );
    } catch (e, st) {
      if (requestSeq != _requestSeq) return;
      await _reporter.report(e, st, context: 'dca_calculate');
      emit(
        DcaFailure(
          assets: currentAssets,
          error: UnknownError(cause: e),
          formInput: updatedForm,
        ),
      );
    }
  }

  Future<void> _onReplayRequested(
    DcaReplayRequested event,
    Emitter<DcaState> emit,
  ) async {
    final assets = _currentAssets();
    final asset = assets
        .where((candidate) => candidate.symbol == event.assetSymbol)
        .firstOrNull;
    if (asset == null ||
        event.amountType != 'try' ||
        !_validPeriods.contains(event.period) ||
        !_datesAreValidForAsset(event.startDate, event.endDate, asset) ||
        !FinancialAmountValidator.isValid(
          value: event.periodicAmount,
          amountType: event.amountType,
          allowedAmountTypes: asset.allowedAmountTypes,
        )) {
      emit(
        DcaFailure(
          assets: assets,
          error: const InvalidScenarioReplayError(),
          formInput: _formInput,
        ),
      );
      return;
    }

    final filled = _formInput.copyWith(
      selectedSymbol: event.assetSymbol,
      startDate: event.startDate,
      endDate: event.endDate,
      periodicAmount: event.periodicAmount,
      period: event.period,
      amountType: event.amountType,
      includeInflation: event.includeInflation,
    );
    _emitWithUpdatedForm(emit, filled);
    await _onCalculateRequested(
      DcaCalculateRequested(
        assetSymbol: event.assetSymbol,
        startDate: event.startDate,
        endDate: event.endDate,
        periodicAmount: event.periodicAmount,
        period: event.period,
        amountType: event.amountType,
        includeInflation: event.includeInflation,
      ),
      emit,
    );
  }

  static const _validPeriods = {'weekly', 'monthly'};

  bool _datesAreValidForAsset(
    DateTime startDate,
    DateTime? endDate,
    Asset asset,
  ) {
    if (!isValidFinancialDateRange(startDate, endDate)) return false;
    final first = asset.firstDate;
    final last = asset.lastDate;
    if (first != null && startDate.isBefore(first)) return false;
    if (last != null && startDate.isAfter(last)) return false;
    if (endDate != null) {
      if (first != null && endDate.isBefore(first)) return false;
      if (last != null && endDate.isAfter(last)) return false;
    }
    return true;
  }

  Future<void> _onLanguageChanged(
    DcaLanguageChanged event,
    Emitter<DcaState> emit,
  ) async {
    final savedForm = _formInput;
    final previous = state;

    try {
      final assets = await _getAssets();
      if (!identical(state, previous)) return;

      if (previous is DcaSuccess) {
        final localizedName = assets
            .where((asset) => asset.symbol == previous.result.assetSymbol)
            .firstOrNull
            ?.displayName;
        emit(
          DcaSuccess(
            assets: assets,
            result: previous.result.withAssetDisplayName(
              localizedName ?? previous.result.assetDisplayName,
            ),
            formInput: savedForm,
          ),
        );
      } else {
        emit(DcaAssetsLoaded(assets, formInput: savedForm));
      }
    } catch (_) {
      // Katalog yenileme başarısızsa mevcut state'i koru.
    }
  }
}
