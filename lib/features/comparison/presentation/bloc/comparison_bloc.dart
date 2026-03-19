import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'comparison_event.dart';
import 'comparison_state.dart';

class ComparisonBloc extends Bloc<ComparisonEvent, ComparisonState> {
  final GetAssets _getAssets;
  final CompareWhatIf _compareWhatIf;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  ComparisonBloc(
    this._getAssets,
    this._compareWhatIf, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter,
       super(const ComparisonInitial()) {
    on<ComparisonAssetsRequested>(_onAssetsRequested);
    on<ComparisonSymbolToggled>(_onSymbolToggled);
    on<ComparisonBuyDateChanged>(_onBuyDateChanged);
    on<ComparisonSellDateChanged>(_onSellDateChanged);
    on<ComparisonAmountChanged>(_onAmountChanged);
    on<ComparisonAmountTypeChanged>(_onAmountTypeChanged);
    on<ComparisonInflationToggled>(_onInflationToggled);
    on<ComparisonCalculateRequested>(_onCalculateRequested);
    on<ComparisonReplayRequested>(_onReplayRequested);
    on<ComparisonLanguageChanged>(_onLanguageChanged);
  }

  ComparisonAssetsLoaded? get _loaded {
    final s = state;
    if (s is ComparisonInitial || s is ComparisonAssetsLoading) return null;
    if (s is ComparisonAssetsLoaded) return s;
    // Success, Failure, Calculating — reconstruct AssetsLoaded so events aren't dropped
    return ComparisonAssetsLoaded(
      assets: s.assets,
      selectedSymbols: s.selectedSymbols,
      buyDate: s.buyDate,
      sellDate: s.sellDate,
      amount: s.amount,
      amountType: s.amountType,
      includeInflation: s.includeInflation,
    );
  }

  Future<void> _onAssetsRequested(
    ComparisonAssetsRequested event,
    Emitter<ComparisonState> emit,
  ) async {
    emit(const ComparisonAssetsLoading());
    try {
      final assets = await _getAssets();
      emit(ComparisonAssetsLoaded(assets: assets));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'comparison_get_assets');
      }
      emit(
        ComparisonFailure(
          assets: const [],
          selectedSymbols: const [],
          error: error,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'comparison_get_assets');
      emit(
        ComparisonFailure(
          assets: const [],
          selectedSymbols: const [],
          error: const UnknownError(),
        ),
      );
    }
  }

  void _onSymbolToggled(
    ComparisonSymbolToggled event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;

    final current = List<String>.from(loaded.selectedSymbols);
    if (current.contains(event.symbol)) {
      current.remove(event.symbol);
    } else if (current.length < 5) {
      current.add(event.symbol);
    }
    emit(loaded.copyWith(selectedSymbols: current));
  }

  void _onBuyDateChanged(
    ComparisonBuyDateChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(buyDate: event.date));
  }

  void _onSellDateChanged(
    ComparisonSellDateChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(sellDate: event.date));
  }

  void _onAmountChanged(
    ComparisonAmountChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(amount: event.amount));
  }

  void _onAmountTypeChanged(
    ComparisonAmountTypeChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(amountType: event.amountType));
  }

  void _onInflationToggled(
    ComparisonInflationToggled event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(includeInflation: !loaded.includeInflation));
  }

  Future<void> _onCalculateRequested(
    ComparisonCalculateRequested event,
    Emitter<ComparisonState> emit,
  ) async {
    final loaded = _loaded;
    if (loaded == null) return;

    emit(
      ComparisonCalculating(
        assets: loaded.assets,
        selectedSymbols: loaded.selectedSymbols,
        buyDate: loaded.buyDate,
        sellDate: loaded.sellDate,
        amount: loaded.amount,
        amountType: loaded.amountType,
        includeInflation: loaded.includeInflation,
      ),
    );

    try {
      final result = await _compareWhatIf(
        assetSymbols: loaded.selectedSymbols,
        buyDate: loaded.buyDate!,
        sellDate: loaded.sellDate,
        amount: loaded.amount!,
        amountType: loaded.amountType,
        includeInflation: loaded.includeInflation,
      );
      emit(
        ComparisonSuccess(
          assets: loaded.assets,
          selectedSymbols: loaded.selectedSymbols,
          buyDate: loaded.buyDate,
          sellDate: loaded.sellDate,
          amount: loaded.amount,
          amountType: loaded.amountType,
          includeInflation: loaded.includeInflation,
          result: result,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'comparison_calculate');
      }
      emit(
        ComparisonFailure(
          assets: loaded.assets,
          selectedSymbols: loaded.selectedSymbols,
          buyDate: loaded.buyDate,
          sellDate: loaded.sellDate,
          amount: loaded.amount,
          amountType: loaded.amountType,
          includeInflation: loaded.includeInflation,
          error: error,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'comparison_calculate');
      emit(
        ComparisonFailure(
          assets: loaded.assets,
          selectedSymbols: loaded.selectedSymbols,
          buyDate: loaded.buyDate,
          sellDate: loaded.sellDate,
          amount: loaded.amount,
          amountType: loaded.amountType,
          includeInflation: loaded.includeInflation,
          error: const UnknownError(),
        ),
      );
    }
  }

  Future<void> _onReplayRequested(
    ComparisonReplayRequested event,
    Emitter<ComparisonState> emit,
  ) async {
    final loaded = _loaded;
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        selectedSymbols: event.symbols,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        includeInflation: event.includeInflation,
      ),
    );
    await _onCalculateRequested(const ComparisonCalculateRequested(), emit);
  }

  Future<void> _onLanguageChanged(
    ComparisonLanguageChanged event,
    Emitter<ComparisonState> emit,
  ) async {
    // Form state'i ve önceki hesaplama sonucunu kaydet
    final savedSymbols = state.selectedSymbols;
    final savedBuyDate = state.buyDate;
    final savedSellDate = state.sellDate;
    final savedAmount = state.amount;
    final savedAmountType = state.amountType;
    final savedInflation = state.includeInflation;
    final hadResult = state is ComparisonSuccess;

    try {
      final assets = await _getAssets();
      final restored = ComparisonAssetsLoaded(
        assets: assets,
        selectedSymbols: savedSymbols,
        buyDate: savedBuyDate,
        sellDate: savedSellDate,
        amount: savedAmount,
        amountType: savedAmountType,
        includeInflation: savedInflation,
      );

      if (hadResult &&
          savedSymbols.length >= 2 &&
          savedBuyDate != null &&
          savedAmount != null) {
        emit(
          ComparisonCalculating(
            assets: assets,
            selectedSymbols: savedSymbols,
            buyDate: savedBuyDate,
            sellDate: savedSellDate,
            amount: savedAmount,
            amountType: savedAmountType,
            includeInflation: savedInflation,
          ),
        );
        try {
          final result = await _compareWhatIf(
            assetSymbols: savedSymbols,
            buyDate: savedBuyDate,
            sellDate: savedSellDate,
            amount: savedAmount,
            amountType: savedAmountType,
            includeInflation: savedInflation,
          );
          emit(
            ComparisonSuccess(
              assets: assets,
              selectedSymbols: savedSymbols,
              buyDate: savedBuyDate,
              sellDate: savedSellDate,
              amount: savedAmount,
              amountType: savedAmountType,
              includeInflation: savedInflation,
              result: result,
            ),
          );
        } catch (_) {
          emit(restored);
        }
      } else {
        emit(restored);
      }
    } catch (_) {
      // Asset fetch başarısız — mevcut state'i koru
    }
  }
}
