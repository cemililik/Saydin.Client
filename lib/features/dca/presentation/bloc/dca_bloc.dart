import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'dca_event.dart';
import 'dca_state.dart';

class DcaBloc extends Bloc<DcaEvent, DcaState> {
  final GetAssets _getAssets;
  final CalculateDca _calculateDca;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  DcaBloc(
    this._getAssets,
    this._calculateDca, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter,
       super(const DcaInitial()) {
    on<DcaAssetsRequested>(_onAssetsRequested);
    on<DcaSymbolChanged>(_onSymbolChanged);
    on<DcaStartDateChanged>(_onStartDateChanged);
    on<DcaEndDateChanged>(_onEndDateChanged);
    on<DcaPeriodChanged>(_onPeriodChanged);
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
      emit(DcaAssetsLoaded(assets, formInput: _formInput));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'dca_get_assets');
      }
      emit(DcaFailure(assets: [], error: error, formInput: _formInput));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'dca_get_assets');
      emit(
        DcaFailure(
          assets: [],
          error: UnknownError(cause: e),
          formInput: _formInput,
        ),
      );
    }
  }

  void _onSymbolChanged(DcaSymbolChanged event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(selectedSymbol: event.symbol),
    );
  }

  void _onStartDateChanged(DcaStartDateChanged event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(startDate: event.date));
  }

  void _onEndDateChanged(DcaEndDateChanged event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(endDate: event.date));
  }

  void _onPeriodChanged(DcaPeriodChanged event, Emitter<DcaState> emit) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(period: event.period));
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
    } else if (current is DcaSuccess) {
      emit(current.copyWith(formInput: updated));
    } else if (current is DcaFailure) {
      emit(current.copyWith(formInput: updated));
    }
  }

  Future<void> _onCalculateRequested(
    DcaCalculateRequested event,
    Emitter<DcaState> emit,
  ) async {
    final currentAssets = _currentAssets();

    await _reporter.addBreadcrumb(
      'DCA calculated: ${event.assetSymbol} ${event.startDate.toIso8601String()}',
      category: 'dca',
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
      emit(
        DcaSuccess(
          assets: currentAssets,
          result: result,
          formInput: updatedForm,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'dca_calculate');
      }
      emit(
        DcaFailure(assets: currentAssets, error: error, formInput: updatedForm),
      );
    } catch (e, st) {
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

  Future<void> _onLanguageChanged(
    DcaLanguageChanged event,
    Emitter<DcaState> emit,
  ) async {
    final savedForm = _formInput;
    final hadResult = state is DcaSuccess;
    final prevAssets = _currentAssets();

    try {
      final assets = await _getAssets();

      if (hadResult) {
        emit(DcaCalculating(assets, formInput: savedForm));
        try {
          final result = await _calculateDca(
            assetSymbol: savedForm.selectedSymbol!,
            startDate: savedForm.startDate!,
            endDate: savedForm.endDate,
            periodicAmount: savedForm.periodicAmount!,
            period: savedForm.period,
            amountType: savedForm.amountType,
            includeInflation: savedForm.includeInflation,
          );
          emit(
            DcaSuccess(assets: assets, result: result, formInput: savedForm),
          );
        } catch (e) {
          emit(DcaAssetsLoaded(assets, formInput: savedForm));
        }
      } else {
        emit(DcaAssetsLoaded(assets, formInput: savedForm));
      }
    } catch (_) {
      if (hadResult) {
        emit(DcaAssetsLoaded(prevAssets, formInput: savedForm));
      }
    }
  }
}
