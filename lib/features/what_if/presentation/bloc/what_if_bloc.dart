import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
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
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  WhatIfBloc(
    this._getAssets,
    this._calculateWhatIf, {
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
    on<WhatIfReplayRequested>(_onReplayRequested);
    on<WhatIfCalculateRequested>(_onCalculateRequested);
  }

  WhatIfFormInput get _formInput => state.formInput;

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
    final assets = switch (state) {
      WhatIfAssetsLoaded(:final assets) => assets,
      WhatIfSuccess(:final assets) => assets,
      WhatIfFailure(:final assets) => assets,
      WhatIfCalculating(:final assets) => assets,
      _ => <Asset>[],
    };
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
    );
    _emitWithUpdatedForm(emit, filled);
    await _onCalculateRequested(
      WhatIfCalculateRequested(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        amountType: event.amountType,
      ),
      emit,
    );
  }

  Future<void> _onCalculateRequested(
    WhatIfCalculateRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final currentAssets = switch (state) {
      WhatIfAssetsLoaded(:final assets) => assets,
      WhatIfSuccess(:final assets) => assets,
      WhatIfFailure(:final assets) => assets,
      WhatIfCalculating(:final assets) => assets,
      _ => <Asset>[],
    };

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
}
