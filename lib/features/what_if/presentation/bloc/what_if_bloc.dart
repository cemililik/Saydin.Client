import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';
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
  final ErrorReporter _reporter;
  int _requestSeq = 0;

  void _invalidateInflightRequests() => _requestSeq++;

  WhatIfBloc(
    this._getAssets,
    this._calculateWhatIf,
    this._calculateReverseWhatIf, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter,
       super(const WhatIfInitial()) {
    on<WhatIfAssetsRequested>(_onAssetsRequested);
    on<WhatIfSymbolChanged>(_onSymbolChanged);
    on<WhatIfBuyDateChanged>(_onBuyDateChanged);
    on<WhatIfSellDateChanged>(_onSellDateChanged);
    on<WhatIfAmountTypeChanged>(_onAmountTypeChanged);
    on<WhatIfAmountChanged>(_onAmountChanged);
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
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'get_assets');
      }
      emit(
        WhatIfFailure(assets: const [], error: error, formInput: _formInput),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'get_assets');
      emit(
        WhatIfFailure(
          assets: const [],
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

    if (newBuyDate != null) {
      final min = firstDate ?? newBuyDate;
      final max = lastDate ?? newBuyDate;
      if (!min.isAfter(max)) {
        final clamped = newBuyDate.clamp(min, max);
        if (clamped != newBuyDate) {
          newBuyDate = clamped;
          dateAdjusted = true;
        }
      }
    }
    if (newSellDate != null) {
      final min = firstDate ?? newSellDate;
      final max = lastDate ?? newSellDate;
      if (!min.isAfter(max)) {
        final clamped = newSellDate.clamp(min, max);
        if (clamped != newSellDate) {
          newSellDate = clamped;
          dateAdjusted = true;
        }
      }
    }
    if (newBuyDate != null &&
        !isValidFinancialDateRange(newBuyDate, newSellDate)) {
      newSellDate = null;
      dateAdjusted = true;
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
    final sellDate =
        event.date != null &&
            !isValidFinancialDateRange(event.date!, _formInput.sellDate)
        ? null
        : _formInput.sellDate;
    _emitWithUpdatedForm(
      emit,
      _formInput.copyWith(buyDate: event.date, sellDate: sellDate),
    );
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

  void _onAmountChanged(WhatIfAmountChanged event, Emitter<WhatIfState> emit) {
    _emitWithUpdatedForm(emit, _formInput.copyWith(amount: event.amount));
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
    } else if (current is WhatIfSuccess || current is WhatIfCalculating) {
      // Form artık sonucu üreten immutable request snapshot'ıyla aynı değil.
      // Eski sonucu kaydetme/paylaşma ihtimalini ortadan kaldır.
      _invalidateInflightRequests();
      emit(WhatIfAssetsLoaded(_currentAssets(), formInput: updated));
    } else if (current is WhatIfFailure) {
      emit(current.copyWith(formInput: updated));
    }
    // WhatIfCalculating: form değişikliği hesaplama süresince yoksayılır
  }

  Future<void> _onReplayRequested(
    WhatIfReplayRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final assets = _currentAssets();
    final asset = assets
        .where((candidate) => candidate.symbol == event.assetSymbol)
        .firstOrNull;
    final allowedAmountTypes = event.calculationMode == CalculationMode.reverse
        ? const <String>['try']
        : asset?.allowedAmountTypes;
    if (asset == null ||
        !_datesAreValidForAsset(event.buyDate, event.sellDate, asset) ||
        !FinancialAmountValidator.isValid(
          value: event.amount,
          amountType: event.amountType,
          allowedAmountTypes: allowedAmountTypes,
        )) {
      emit(
        WhatIfFailure(
          assets: assets,
          error: const InvalidScenarioReplayError(),
          formInput: _formInput,
        ),
      );
      return;
    }

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
    final asset = currentAssets
        .where((candidate) => candidate.symbol == event.assetSymbol)
        .firstOrNull;
    if (asset == null ||
        !_datesAreValidForAsset(event.buyDate, event.sellDate, asset) ||
        !FinancialAmountValidator.isValid(
          value: event.amount,
          amountType: event.amountType,
          allowedAmountTypes: asset.allowedAmountTypes,
        )) {
      return;
    }

    await _reporter.recordAction(
      'what_if.calculated',
      category: 'what_if',
      data: const {'feature': 'what_if', 'action': 'calculated'},
    );

    final requestForm = _formInput.copyWith(
      selectedSymbol: event.assetSymbol,
      buyDate: event.buyDate,
      sellDate: event.sellDate,
      amount: event.amount,
      amountType: event.amountType,
      includeInflation: event.includeInflation,
      calculationMode: CalculationMode.normal,
    );
    final requestSeq = ++_requestSeq;
    emit(WhatIfCalculating(currentAssets, formInput: requestForm));
    try {
      final result = await _calculateWhatIf(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        amountType: event.amountType,
        includeInflation: event.includeInflation,
      );
      if (requestSeq != _requestSeq) return;
      emit(
        WhatIfSuccess(
          assets: currentAssets,
          result: result,
          formInput: requestForm,
        ),
      );
    } on AppError catch (error, st) {
      if (requestSeq != _requestSeq) return;
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'calculate_what_if');
      }
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: error,
          formInput: requestForm,
        ),
      );
    } catch (e, st) {
      if (requestSeq != _requestSeq) return;
      await _reporter.report(e, st, context: 'calculate_what_if');
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: UnknownError(cause: e),
          formInput: requestForm,
        ),
      );
    }
  }

  Future<void> _onReverseCalculateRequested(
    WhatIfReverseCalculateRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    final currentAssets = _currentAssets();
    final asset = currentAssets
        .where((candidate) => candidate.symbol == event.assetSymbol)
        .firstOrNull;
    if (asset == null ||
        event.targetAmountType != 'try' ||
        !_datesAreValidForAsset(event.buyDate, event.sellDate, asset) ||
        !FinancialAmountValidator.isValid(
          value: event.targetAmount,
          amountType: event.targetAmountType,
          allowedAmountTypes: asset.allowedAmountTypes,
        )) {
      return;
    }

    await _reporter.recordAction(
      'what_if.reverse_calculated',
      category: 'what_if',
      data: const {'feature': 'what_if', 'action': 'reverse_calculated'},
    );

    final requestForm = _formInput.copyWith(
      selectedSymbol: event.assetSymbol,
      buyDate: event.buyDate,
      sellDate: event.sellDate,
      amount: event.targetAmount,
      amountType: event.targetAmountType,
      includeInflation: event.includeInflation,
      calculationMode: CalculationMode.reverse,
    );
    final requestSeq = ++_requestSeq;
    emit(WhatIfCalculating(currentAssets, formInput: requestForm));
    try {
      final result = await _calculateReverseWhatIf(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        targetAmount: event.targetAmount,
        targetAmountType: event.targetAmountType,
        includeInflation: event.includeInflation,
      );
      if (requestSeq != _requestSeq) return;
      emit(
        WhatIfSuccess(
          assets: currentAssets,
          reverseResult: result,
          formInput: requestForm,
        ),
      );
    } on AppError catch (error, st) {
      if (requestSeq != _requestSeq) return;
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'reverse_calculate_what_if');
      }
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: error,
          formInput: requestForm,
        ),
      );
    } catch (e, st) {
      if (requestSeq != _requestSeq) return;
      await _reporter.report(e, st, context: 'reverse_calculate_what_if');
      emit(
        WhatIfFailure(
          assets: currentAssets,
          error: UnknownError(cause: e),
          formInput: requestForm,
        ),
      );
    }
  }

  bool _datesAreValidForAsset(
    DateTime buyDate,
    DateTime? sellDate,
    Asset asset,
  ) {
    if (!isValidFinancialDateRange(buyDate, sellDate)) return false;
    final first = asset.firstDate;
    final last = asset.lastDate;
    if (first != null && buyDate.isBefore(first)) return false;
    if (last != null && buyDate.isAfter(last)) return false;
    if (sellDate != null) {
      if (first != null && sellDate.isBefore(first)) return false;
      if (last != null && sellDate.isAfter(last)) return false;
    }
    return true;
  }

  Future<void> _onLanguageChanged(
    WhatIfLanguageChanged event,
    Emitter<WhatIfState> emit,
  ) async {
    // Locale değişimi finansal hesap değildir: kota tüketmeden yalnız katalog
    // adlarını yenile ve varsa sonuç snapshot'ını aynen koru.
    final savedForm = _formInput;
    final previous = state;

    try {
      final assets = await _getAssets();
      if (!identical(state, previous)) return;

      if (previous is WhatIfSuccess) {
        final result = previous.result;
        final reverseResult = previous.reverseResult;
        emit(
          WhatIfSuccess(
            assets: assets,
            result: result?.withAssetDisplayName(
              _localizedAssetName(
                assets,
                result.assetSymbol,
                result.assetDisplayName,
              ),
            ),
            reverseResult: reverseResult?.withAssetDisplayName(
              _localizedAssetName(
                assets,
                reverseResult.assetSymbol,
                reverseResult.assetDisplayName,
              ),
            ),
            formInput: savedForm,
          ),
        );
      } else {
        emit(WhatIfAssetsLoaded(assets, formInput: savedForm));
      }
    } catch (_) {
      // Katalog yenileme başarısızsa sonuç ve form dahil mevcut state korunur.
    }
  }

  String _localizedAssetName(
    List<Asset> assets,
    String symbol,
    String fallback,
  ) =>
      assets
          .where((asset) => asset.symbol == symbol)
          .firstOrNull
          ?.displayName ??
      fallback;
}
