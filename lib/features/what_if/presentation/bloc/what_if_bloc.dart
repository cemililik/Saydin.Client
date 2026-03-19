import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_reverse_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'what_if_event.dart';
import 'what_if_state.dart';

extension on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}

class WhatIfBloc extends Bloc<WhatIfEvent, WhatIfState> {
  final GetAssets _getAssets;
  final CalculateWhatIf _calculateWhatIf;
  final CalculateReverseWhatIf _calculateReverseWhatIf;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  WhatIfBloc(
    this._getAssets,
    this._calculateWhatIf,
    this._calculateReverseWhatIf, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter,
       super(const WhatIfInitial()) {
    on<WhatIfAssetsRequested>(_onAssetsRequested);
    on<WhatIfSymbolChanged>(_onSymbolChanged);
    on<WhatIfBuyDateChanged>(_onBuyDateChanged);
    on<WhatIfSellDateChanged>(_onSellDateChanged);
    on<WhatIfAmountTypeChanged>(_onAmountTypeChanged);
    on<WhatIfInflationToggled>(_onInflationToggled);
    on<WhatIfModeChanged>(_onModeChanged);
    on<WhatIfReplayRequested>(_onReplayRequested);
    on<WhatIfCalculateRequested>(_onCalculateRequested);
    on<WhatIfReverseCalculateRequested>(_onReverseCalculateRequested);
    on<WhatIfLanguageChanged>(_onLanguageChanged);
  }

  WhatIfFormInput get _formInput => state.formInput;

  /// Mevcut assets listesinden sembol listesi çıkarır.
  List<Asset> _currentAssets() => switch (state) {
    WhatIfAssetsLoaded(:final assets) => assets,
    WhatIfSuccess(:final assets) => assets,
    WhatIfFailure(:final assets) => assets,
    WhatIfCalculating(:final assets) => assets,
    _ => <Asset>[],
  };

  Future<void> _onAssetsRequested(
    WhatIfAssetsRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    emit(const WhatIfAssetsLoading());
    try {
      final assets = await _getAssets();
      emit(WhatIfAssetsLoaded(assets, formInput: _formInput));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'get_assets');
      }
      emit(WhatIfFailure(assets: [], error: error, formInput: _formInput));
    } catch (e, st) {
      await _reporter.report(e, st, context: 'get_assets');
      emit(
        WhatIfFailure(
          assets: [],
          error: UnknownError(cause: e),
          formInput: _formInput,
        ),
      );
    }
  }

  void _onSymbolChanged(WhatIfSymbolChanged event, Emitter<WhatIfState> emit) {
    final assets = _currentAssets();
    final asset = assets.where((a) => a.symbol == event.symbol).firstOrNull;
    final allowed = asset?.allowedAmountTypes ?? ['try'];
    final newAmountType = allowed.contains(_formInput.amountType)
        ? _formInput.amountType
        : 'try';

    // Seçili tarihler yeni asset'in veri aralığı dışındaysa en yakın geçerli tarihe sıkıştır.
    final firstDate = asset?.firstDate;
    final lastDate = asset?.lastDate;
    var newBuyDate = _formInput.buyDate;
    var newSellDate = _formInput.sellDate;
    var dateAdjusted = false;

    if (firstDate != null && lastDate != null) {
      if (newBuyDate != null) {
        final clamped = newBuyDate.clamp(firstDate, lastDate);
        if (clamped != newBuyDate) {
          newBuyDate = clamped;
          dateAdjusted = true;
        }
      }
      if (newSellDate != null) {
        final clamped = newSellDate.clamp(firstDate, lastDate);
        if (clamped != newSellDate) {
          newSellDate = clamped;
          dateAdjusted = true;
        }
      }
    }

    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(
        selectedSymbol: event.symbol,
        amountType: newAmountType,
        buyDate: newBuyDate,
        sellDate: newSellDate,
        dateAdjusted: dateAdjusted,
      ),
    );
  }

  void _onBuyDateChanged(
    WhatIfBuyDateChanged event,
    Emitter<WhatIfState> emit,
  ) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(buyDate: event.date));
  }

  void _onSellDateChanged(
    WhatIfSellDateChanged event,
    Emitter<WhatIfState> emit,
  ) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(sellDate: event.date));
  }

  void _onAmountTypeChanged(
    WhatIfAmountTypeChanged event,
    Emitter<WhatIfState> emit,
  ) {
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(amountType: event.amountType),
    );
  }

  void _onInflationToggled(
    WhatIfInflationToggled event,
    Emitter<WhatIfState> emit,
  ) {
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(includeInflation: !_formInput.includeInflation),
    );
  }

  void _onModeChanged(WhatIfModeChanged event, Emitter<WhatIfState> emit) {
    final updated = event.mode == CalculationMode.reverse
        ? _formInput.copyWith(calculationMode: event.mode, amountType: 'try')
        : _formInput.copyWith(calculationMode: event.mode);
    _emitWithUpdatedForm(emit, updated);
  }

  void _emitWithUpdatedForm(
    Emitter<WhatIfState> emit,
    WhatIfFormInput updated,
  ) {
    final current = state;
    if (current is WhatIfAssetsLoaded) {
      emit(current.copyWith(formInput: updated));
    } else if (current is WhatIfSuccess) {
      emit(current.copyWith(formInput: updated));
    } else if (current is WhatIfFailure) {
      emit(current.copyWith(formInput: updated));
    }
    // WhatIfCalculating: form değişikliği hesaplama süresince yoksayılır
  }

  Future<void> _onReplayRequested(
    WhatIfReplayRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final filled = _formInput.copyWith(
      selectedSymbol: event.assetSymbol,
      buyDate: event.buyDate,
      sellDate: event.sellDate,
      amountType: event.amountType,
      amount: event.amount,
      includeInflation: event.includeInflation,
      calculationMode: event.calculationMode,
    );
    _emitWithUpdatedForm(emit, filled);

    if (event.calculationMode == CalculationMode.reverse) {
      await _onReverseCalculateRequested(
        WhatIfReverseCalculateRequested(
          assetSymbol: event.assetSymbol,
          buyDate: event.buyDate,
          sellDate: event.sellDate,
          targetAmount: event.amount,
          targetAmountType: event.amountType,
          includeInflation: event.includeInflation,
        ),
        emit,
      );
    } else {
      await _onCalculateRequested(
        WhatIfCalculateRequested(
          assetSymbol: event.assetSymbol,
          buyDate: event.buyDate,
          sellDate: event.sellDate,
          amount: event.amount,
          amountType: event.amountType,
          includeInflation: event.includeInflation,
        ),
        emit,
      );
    }
  }

  Future<void> _onCalculateRequested(
    WhatIfCalculateRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final currentAssets = _currentAssets();

    await _reporter.addBreadcrumb(
      'WhatIf calculated: ${event.assetSymbol} ${event.buyDate.toIso8601String()}',
      category: 'what_if',
    );

    emit(WhatIfCalculating(currentAssets, formInput: _formInput));
    try {
      final result = await _calculateWhatIf(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        amountType: event.amountType,
        includeInflation: event.includeInflation,
      );
      emit(
        WhatIfSuccess(
          assets: currentAssets,
          result: result,
          formInput: _formInput,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'calculate_what_if');
      }
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: error,
          formInput: _formInput,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'calculate_what_if');
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: UnknownError(cause: e),
          formInput: _formInput,
        ),
      );
    }
  }

  Future<void> _onReverseCalculateRequested(
    WhatIfReverseCalculateRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final currentAssets = _currentAssets();

    await _reporter.addBreadcrumb(
      'ReverseWhatIf calculated: ${event.assetSymbol} ${event.buyDate.toIso8601String()}',
      category: 'what_if',
    );

    emit(WhatIfCalculating(currentAssets, formInput: _formInput));
    try {
      final result = await _calculateReverseWhatIf(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        targetAmount: event.targetAmount,
        targetAmountType: event.targetAmountType,
        includeInflation: event.includeInflation,
      );
      emit(
        WhatIfSuccess(
          assets: currentAssets,
          reverseResult: result,
          formInput: _formInput,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'reverse_calculate_what_if');
      }
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: error,
          formInput: _formInput,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'reverse_calculate_what_if');
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: UnknownError(cause: e),
          formInput: _formInput,
        ),
      );
    }
  }

  Future<void> _onLanguageChanged(
    WhatIfLanguageChanged event,
    Emitter<WhatIfState> emit,
  ) async {
    // Form state'i ve önceki hesaplama sonucunu kaydet
    final savedForm = _formInput;
    final hadResult = state is WhatIfSuccess;
    final prevAssets = _currentAssets();

    try {
      final assets = await _getAssets();

      if (hadResult) {
        // Önceki hesaplama sonucu vardı — yeni asset'lerle yeniden hesapla
        emit(WhatIfCalculating(assets, formInput: savedForm));
        try {
          if (savedForm.calculationMode == CalculationMode.reverse) {
            final result = await _calculateReverseWhatIf(
              assetSymbol: savedForm.selectedSymbol!,
              buyDate: savedForm.buyDate!,
              sellDate: savedForm.sellDate,
              targetAmount: savedForm.amount!,
              targetAmountType: savedForm.amountType,
              includeInflation: savedForm.includeInflation,
            );
            emit(
              WhatIfSuccess(
                assets: assets,
                reverseResult: result,
                formInput: savedForm,
              ),
            );
          } else {
            final result = await _calculateWhatIf(
              assetSymbol: savedForm.selectedSymbol!,
              buyDate: savedForm.buyDate!,
              sellDate: savedForm.sellDate,
              amount: savedForm.amount!,
              amountType: savedForm.amountType,
              includeInflation: savedForm.includeInflation,
            );
            emit(
              WhatIfSuccess(
                assets: assets,
                result: result,
                formInput: savedForm,
              ),
            );
          }
        } catch (e) {
          // Hesaplama başarısız olursa en azından yeni asset'lerle form korunsun
          emit(WhatIfAssetsLoaded(assets, formInput: savedForm));
        }
      } else {
        emit(WhatIfAssetsLoaded(assets, formInput: savedForm));
      }
    } catch (_) {
      // Asset fetch başarısız — mevcut state'i koru
      if (hadResult) {
        emit(WhatIfAssetsLoaded(prevAssets, formInput: savedForm));
      }
    }
  }
}
