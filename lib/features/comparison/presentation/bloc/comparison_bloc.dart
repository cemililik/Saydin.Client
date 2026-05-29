import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
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
    _invalidateInflightRequests();
    emit(loaded.copyWith(selectedSymbols: current));
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
