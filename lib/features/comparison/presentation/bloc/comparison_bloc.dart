import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'comparison_event.dart';
import 'comparison_state.dart';

class ComparisonBloc extends Bloc<ComparisonEvent, ComparisonState> {
  final GetAssets _getAssets;
  final CompareWhatIf _compareWhatIf;
  final ErrorReporter _reporter;

  /// Monotonik istek sayacı. Her `_onCalculateRequested` başlangıcında
  /// artar; uçuştaki istek tamamlanırken form mutasyonu yapıldıysa
  /// (`_invalidateInflightRequests`) sayaç ileri taşınır ve eski cevap
  /// `emit` etmeden atılır. Bu, kullanıcının ekrandaki seçimleriyle
  /// uyuşmayan bir `Success` snapshot'ın bastırılmasını önler.
  int _requestSeq = 0;

  ComparisonBloc(
    this._getAssets,
    this._compareWhatIf, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter,
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

  /// Form alanlarından biri değiştiğinde çağrılır; uçuşta olan
  /// `_onCalculateRequested` cevabını geçersiz kılar.
  void _invalidateInflightRequests() => _requestSeq++;

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
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'comparison_get_assets');
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
        const ComparisonFailure(
          assets: [],
          selectedSymbols: [],
          error: UnknownError(),
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
    final range = comparisonDateRange(
      assets: loaded.assets,
      selectedSymbols: current,
      priceHistoryMonths: 0,
    );
    final buyDate = _clampDate(loaded.buyDate, range);
    var sellDate = _clampDate(loaded.sellDate, range);
    if (buyDate != null && sellDate != null && sellDate.isBefore(buyDate)) {
      sellDate = null;
    }
    _invalidateInflightRequests();
    emit(
      loaded.copyWith(
        selectedSymbols: current,
        buyDate: buyDate,
        sellDate: sellDate,
      ),
    );
  }

  DateTime? _clampDate(DateTime? date, ComparisonDateRange range) {
    if (date == null || !range.hasOverlap) return null;
    final first = range.firstDate;
    final last = range.lastDate;
    if (first != null && date.isBefore(first)) return first;
    if (last != null && date.isAfter(last)) return last;
    return date;
  }

  void _onBuyDateChanged(
    ComparisonBuyDateChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    _invalidateInflightRequests();
    emit(loaded.copyWith(buyDate: event.date));
  }

  void _onSellDateChanged(
    ComparisonSellDateChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    _invalidateInflightRequests();
    emit(loaded.copyWith(sellDate: event.date));
  }

  void _onAmountChanged(
    ComparisonAmountChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    _invalidateInflightRequests();
    emit(loaded.copyWith(amount: event.amount));
  }

  void _onAmountTypeChanged(
    ComparisonAmountTypeChanged event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    _invalidateInflightRequests();
    emit(loaded.copyWith(amountType: event.amountType));
  }

  void _onInflationToggled(
    ComparisonInflationToggled event,
    Emitter<ComparisonState> emit,
  ) {
    final loaded = _loaded;
    if (loaded == null) return;
    _invalidateInflightRequests();
    emit(loaded.copyWith(includeInflation: !loaded.includeInflation));
  }

  Future<void> _onCalculateRequested(
    ComparisonCalculateRequested event,
    Emitter<ComparisonState> emit,
  ) async {
    final loaded = _loaded;
    if (loaded == null) return;
    // buyDate/amount eksikse hesaplama yapma. Page guard'ları bunu önler ama
    // replay/edge path'lerde aşağıdaki `!` crash'ini eleyen defense-in-depth.
    final buyDate = loaded.buyDate;
    final amount = loaded.amount;
    if (buyDate == null || amount == null) return;
    if (!_isValidCalculationInput(loaded)) return;

    // Bu istek için anlık snapshot. `_invalidateInflightRequests` (form
    // mutasyon handler'ları) sayacı ileri taşırsa uçuştaki cevap atılır.
    final requestSeq = ++_requestSeq;

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
        buyDate: buyDate,
        sellDate: loaded.sellDate,
        amount: amount,
        amountType: loaded.amountType,
        includeInflation: loaded.includeInflation,
      );
      if (requestSeq != _requestSeq) return;
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
    } on AppError catch (error, st) {
      if (requestSeq != _requestSeq) return;
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'comparison_calculate');
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
      if (requestSeq != _requestSeq) return;
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
    final replay = loaded.copyWith(
      selectedSymbols: List<String>.unmodifiable(event.symbols),
      buyDate: event.buyDate,
      sellDate: event.sellDate,
      amount: event.amount,
      amountType: event.amountType,
      includeInflation: event.includeInflation,
    );
    if (!_isValidCalculationInput(replay)) {
      emit(
        ComparisonFailure(
          assets: loaded.assets,
          selectedSymbols: loaded.selectedSymbols,
          buyDate: loaded.buyDate,
          sellDate: loaded.sellDate,
          amount: loaded.amount,
          amountType: loaded.amountType,
          includeInflation: loaded.includeInflation,
          error: const InvalidScenarioReplayError(),
        ),
      );
      return;
    }
    emit(replay);
    await _onCalculateRequested(const ComparisonCalculateRequested(), emit);
  }

  bool _isValidCalculationInput(ComparisonAssetsLoaded loaded) {
    final buyDate = loaded.buyDate;
    final amount = loaded.amount;
    if (buyDate == null || amount == null) return false;
    final knownSymbols = loaded.assets.map((asset) => asset.symbol).toSet();
    final uniqueSymbols = loaded.selectedSymbols.toSet();
    final range = comparisonDateRange(
      assets: loaded.assets,
      selectedSymbols: loaded.selectedSymbols,
      priceHistoryMonths: 0,
    );
    final sellDate = loaded.sellDate;
    bool isOutsideRange(DateTime date) =>
        (range.firstDate != null && date.isBefore(range.firstDate!)) ||
        (range.lastDate != null && date.isAfter(range.lastDate!));

    return uniqueSymbols.length >= 2 &&
        uniqueSymbols.length <= 5 &&
        uniqueSymbols.length == loaded.selectedSymbols.length &&
        uniqueSymbols.every(knownSymbols.contains) &&
        range.hasOverlap &&
        !isOutsideRange(buyDate) &&
        (sellDate == null || !isOutsideRange(sellDate)) &&
        isValidFinancialDateRange(buyDate, sellDate) &&
        FinancialAmountValidator.isValid(
          value: amount,
          amountType: loaded.amountType,
          allowedAmountTypes: const ['try'],
        );
  }

  Future<void> _onLanguageChanged(
    ComparisonLanguageChanged event,
    Emitter<ComparisonState> emit,
  ) async {
    final previous = state;

    try {
      final assets = await _getAssets();
      if (!identical(state, previous)) return;
      if (previous is ComparisonSuccess) {
        final localizedResult = CompareResult(
          results: previous.result.results
              .map(
                (item) => CompareResultItem(
                  rank: item.rank,
                  calculation: item.calculation.withAssetDisplayName(
                    assets
                            .where(
                              (asset) =>
                                  asset.symbol == item.calculation.assetSymbol,
                            )
                            .firstOrNull
                            ?.displayName ??
                        item.calculation.assetDisplayName,
                  ),
                ),
              )
              .toList(growable: false),
        );
        emit(
          ComparisonSuccess(
            assets: assets,
            selectedSymbols: previous.selectedSymbols,
            buyDate: previous.buyDate,
            sellDate: previous.sellDate,
            amount: previous.amount,
            amountType: previous.amountType,
            includeInflation: previous.includeInflation,
            result: localizedResult,
          ),
        );
      } else {
        emit(
          ComparisonAssetsLoaded(
            assets: assets,
            selectedSymbols: previous.selectedSymbols,
            buyDate: previous.buyDate,
            sellDate: previous.sellDate,
            amount: previous.amount,
            amountType: previous.amountType,
            includeInflation: previous.includeInflation,
          ),
        );
      }
    } catch (_) {
      // Asset fetch başarısız — mevcut state'i koru
    }
  }
}
