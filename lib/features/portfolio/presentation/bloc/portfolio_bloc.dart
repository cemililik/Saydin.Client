import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:uuid/uuid.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetAssets _getAssets;
  final CalculatePortfolio _calculatePortfolio;
  final ErrorReporter _reporter;

  static const _uuid = Uuid();
  int _requestSeq = 0;

  void _invalidateInflightRequests() => _requestSeq++;

  PortfolioBloc(
    this._getAssets,
    this._calculatePortfolio, {
    ErrorReporter reporter = const ErrorReporter(),
  }) : _reporter = reporter,
       super(const PortfolioInitial()) {
    on<PortfolioAssetsRequested>(_onAssetsRequested);
    on<PortfolioBuyDateChanged>(_onBuyDateChanged);
    on<PortfolioSellDateChanged>(_onSellDateChanged);
    on<PortfolioItemAdded>(_onItemAdded);
    on<PortfolioItemUpdated>(_onItemUpdated);
    on<PortfolioItemRemoved>(_onItemRemoved);
    on<PortfolioCalculateRequested>(_onCalculateRequested);
    on<PortfolioInflationToggled>(_onInflationToggled);
    on<PortfolioReset>(_onReset);
    on<PortfolioReplayRequested>(_onReplayRequested);
    on<PortfolioLanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onAssetsRequested(
    PortfolioAssetsRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    // assets.isNotEmpty post-load durumunu yakalar; uçuştaki fetch sırasında
    // (state PortfolioAssetsLoading, assets hâlâ boş) ikinci bir istek gelirse
    // mükerrer _getAssets + last-writer-wins yarışını önlemek için onu da ele.
    if (state.assets.isNotEmpty || state is PortfolioAssetsLoading) return;
    emit(
      PortfolioAssetsLoading(
        items: state.items,
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
    try {
      final assets = await _getAssets();
      final dates = _normalizedDates(
        state.items,
        state.buyDate,
        state.sellDate,
        assets: assets,
      );
      emit(
        PortfolioEditing(
          assets: assets,
          items: state.items,
          buyDate: dates.buyDate,
          sellDate: dates.sellDate,
          includeInflation: state.includeInflation,
        ),
      );
    } on AppError catch (error, st) {
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'portfolio_get_assets');
      }
      emit(
        PortfolioFailure(
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          error: error,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'portfolio_get_assets');
      emit(
        PortfolioFailure(
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  void _onBuyDateChanged(
    PortfolioBuyDateChanged event,
    Emitter<PortfolioState> emit,
  ) {
    _invalidateInflightRequests();
    final sellDate =
        event.date != null &&
            !isValidFinancialDateRange(event.date!, state.sellDate)
        ? null
        : state.sellDate;
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: state.items,
        buyDate: event.date,
        sellDate: sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onSellDateChanged(
    PortfolioSellDateChanged event,
    Emitter<PortfolioState> emit,
  ) {
    _invalidateInflightRequests();
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: state.items,
        buyDate: state.buyDate,
        sellDate: event.date,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onItemAdded(PortfolioItemAdded event, Emitter<PortfolioState> emit) {
    // F-09-09: max kalem sınırı (defense-in-depth; UI butonu da disable eder +
    // snackbar gösterir). BLoC snackbar gösteremediği için burada sessiz no-op.
    if (state.items.length >= PortfolioConstants.maxItems ||
        state.items.any((item) => item.assetSymbol == event.assetSymbol)) {
      return;
    }
    if (!_isValidItemAmount(
      event.assetSymbol,
      event.amount,
      event.amountType,
    )) {
      return;
    }
    _invalidateInflightRequests();
    final newItem = PortfolioItem(
      id: _uuid.v4(),
      assetSymbol: event.assetSymbol,
      assetDisplayName: event.assetDisplayName,
      amount: event.amount,
      amountType: event.amountType,
    );
    final items = [...state.items, newItem];
    final dates = _normalizedDates(items, state.buyDate, state.sellDate);
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: items,
        buyDate: dates.buyDate,
        sellDate: dates.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onItemUpdated(
    PortfolioItemUpdated event,
    Emitter<PortfolioState> emit,
  ) {
    if (state.items.any(
          (item) =>
              item.id != event.id && item.assetSymbol == event.assetSymbol,
        ) ||
        !_isValidItemAmount(
          event.assetSymbol,
          event.amount,
          event.amountType,
        )) {
      return;
    }
    _invalidateInflightRequests();
    final updatedItems = state.items.map((item) {
      if (item.id == event.id) {
        return PortfolioItem(
          id: item.id,
          assetSymbol: event.assetSymbol,
          assetDisplayName: event.assetDisplayName,
          amount: event.amount,
          amountType: event.amountType,
        );
      }
      return item;
    }).toList();

    final dates = _normalizedDates(updatedItems, state.buyDate, state.sellDate);
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: updatedItems,
        buyDate: dates.buyDate,
        sellDate: dates.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onItemRemoved(
    PortfolioItemRemoved event,
    Emitter<PortfolioState> emit,
  ) {
    _invalidateInflightRequests();
    final items = state.items.where((i) => i.id != event.id).toList();
    final dates = _normalizedDates(items, state.buyDate, state.sellDate);
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: items,
        buyDate: dates.buyDate,
        sellDate: dates.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  Future<void> _onCalculateRequested(
    PortfolioCalculateRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    final buyDate = state.buyDate;
    if (buyDate == null ||
        state.items.isEmpty ||
        state.items.length > PortfolioConstants.maxItems ||
        state.items.map((item) => item.assetSymbol).toSet().length !=
            state.items.length) {
      return;
    }
    final range = _rangeFor(state.items);
    final datesValid =
        range.hasOverlap &&
        (range.firstDate == null || !buyDate.isBefore(range.firstDate!)) &&
        (range.lastDate == null || !buyDate.isAfter(range.lastDate!)) &&
        isValidFinancialDateRange(buyDate, state.sellDate);
    final amountsValid = state.items.every((item) {
      final asset = state.assets
          .where((candidate) => candidate.symbol == item.assetSymbol)
          .firstOrNull;
      return asset != null &&
          FinancialAmountValidator.isValid(
            value: item.amount,
            amountType: item.amountType,
            allowedAmountTypes: asset.allowedAmountTypes,
          );
    });
    if (!datesValid || !amountsValid) return;
    final requestSeq = ++_requestSeq;
    final assets = state.assets;
    final items = List<PortfolioItem>.unmodifiable(state.items);
    final sellDate = state.sellDate;
    final includeInflation = state.includeInflation;

    emit(
      PortfolioCalculating(
        assets: assets,
        items: items,
        buyDate: buyDate,
        sellDate: sellDate,
        includeInflation: includeInflation,
      ),
    );
    try {
      final result = await _calculatePortfolio(
        items: items,
        buyDate: buyDate,
        sellDate: sellDate,
        includeInflation: includeInflation,
      );
      if (requestSeq != _requestSeq) return;
      emit(
        PortfolioSuccess(
          assets: assets,
          items: items,
          buyDate: buyDate,
          sellDate: sellDate,
          includeInflation: includeInflation,
          result: result,
        ),
      );
    } on AppError catch (error, st) {
      if (requestSeq != _requestSeq) return;
      if (error is UnknownError ||
          error is ServerError ||
          error is MalformedResponseError) {
        await _reporter.report(error, st, context: 'portfolio_calculate');
      }
      emit(
        PortfolioFailure(
          assets: assets,
          items: items,
          buyDate: buyDate,
          sellDate: sellDate,
          includeInflation: includeInflation,
          error: error,
        ),
      );
    } catch (error, st) {
      if (requestSeq != _requestSeq) return;
      await _reporter.report(error, st, context: 'portfolio_calculate');
      emit(
        PortfolioFailure(
          assets: assets,
          items: items,
          buyDate: buyDate,
          sellDate: sellDate,
          includeInflation: includeInflation,
          error: UnknownError(cause: error),
        ),
      );
    }
  }

  void _onInflationToggled(
    PortfolioInflationToggled event,
    Emitter<PortfolioState> emit,
  ) {
    _invalidateInflightRequests();
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: state.items,
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: !state.includeInflation,
      ),
    );
  }

  void _onReset(PortfolioReset event, Emitter<PortfolioState> emit) {
    _invalidateInflightRequests();
    emit(PortfolioEditing(assets: state.assets));
  }

  Future<void> _onReplayRequested(
    PortfolioReplayRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    _invalidateInflightRequests();
    final localizedItems = event.items
        .map((item) {
          final currentAsset = state.assets
              .where((asset) => asset.symbol == item.assetSymbol)
              .firstOrNull;
          return currentAsset == null
              ? item
              : item.withDisplayName(currentAsset.displayName);
        })
        .toList(growable: false);
    final symbols = localizedItems.map((item) => item.assetSymbol).toSet();
    final replayIsValid =
        localizedItems.isNotEmpty &&
        localizedItems.length <= PortfolioConstants.maxItems &&
        symbols.length == localizedItems.length &&
        localizedItems.every(
          (item) => _isValidItemAmount(
            item.assetSymbol,
            item.amount,
            item.amountType,
          ),
        );
    final dates = _normalizedDates(
      localizedItems,
      event.buyDate,
      event.sellDate,
    );
    if (!replayIsValid ||
        dates.buyDate != event.buyDate ||
        dates.sellDate != event.sellDate) {
      emit(
        PortfolioFailure(
          assets: state.assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          error: const InvalidScenarioReplayError(),
        ),
      );
      return;
    }
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: localizedItems,
        buyDate: dates.buyDate,
        sellDate: dates.sellDate,
        includeInflation: event.includeInflation,
      ),
    );
    if (localizedItems.isNotEmpty) {
      await _onCalculateRequested(const PortfolioCalculateRequested(), emit);
    }
  }

  Future<void> _onLanguageChanged(
    PortfolioLanguageChanged event,
    Emitter<PortfolioState> emit,
  ) async {
    _invalidateInflightRequests();
    final previous = state;

    try {
      final assets = await _getAssets();
      if (!identical(state, previous)) return;

      if (previous is PortfolioSuccess) {
        final localizedItems = previous.items
            .map(
              (item) => item.withDisplayName(
                assets
                        .where((asset) => asset.symbol == item.assetSymbol)
                        .firstOrNull
                        ?.displayName ??
                    item.assetDisplayName,
              ),
            )
            .toList(growable: false);
        final itemsById = {for (final item in localizedItems) item.id: item};
        final result = _localizeResult(previous.result, itemsById);
        emit(
          PortfolioSuccess(
            assets: assets,
            items: localizedItems,
            buyDate: previous.buyDate,
            sellDate: previous.sellDate,
            includeInflation: previous.includeInflation,
            result: result,
          ),
        );
      } else {
        emit(
          PortfolioEditing(
            assets: assets,
            items: previous.items,
            buyDate: previous.buyDate,
            sellDate: previous.sellDate,
            includeInflation: previous.includeInflation,
          ),
        );
      }
    } catch (_) {
      // Asset fetch başarısız — mevcut state'i koru
    }
  }

  PortfolioResult _localizeResult(
    PortfolioResult result,
    Map<String, PortfolioItem> itemsById,
  ) => PortfolioResult(
    items: result.items
        .map(
          (item) => PortfolioItemResult(
            item: itemsById[item.item.id] ?? item.item,
            calculation: item.calculation,
            sharePercent: item.sharePercent,
          ),
        )
        .toList(growable: false),
    failures: result.failures
        .map(
          (failure) => PortfolioItemFailure(
            item: itemsById[failure.item.id] ?? failure.item,
            error: failure.error,
          ),
        )
        .toList(growable: false),
    totalInitialValueTry: result.totalInitialValueTry,
    totalFinalValueTry: result.totalFinalValueTry,
    totalProfitLossTry: result.totalProfitLossTry,
    totalProfitLossPercent: result.totalProfitLossPercent,
    isProfit: result.isProfit,
    effectiveSellDate: result.effectiveSellDate,
    totalRealProfitLossTry: result.totalRealProfitLossTry,
    totalRealProfitLossPercent: result.totalRealProfitLossPercent,
    totalCumulativeInflationPercent: result.totalCumulativeInflationPercent,
  );

  bool _isValidItemAmount(String symbol, Decimal amount, String amountType) {
    final asset = state.assets
        .where((candidate) => candidate.symbol == symbol)
        .firstOrNull;
    return asset != null &&
        FinancialAmountValidator.isValid(
          value: amount,
          amountType: amountType,
          allowedAmountTypes: asset.allowedAmountTypes,
        );
  }

  ComparisonDateRange _rangeFor(
    List<PortfolioItem> items, {
    List<Asset>? assets,
  }) {
    final availableAssets = assets ?? state.assets;
    final symbols = items
        .map((item) => item.assetSymbol)
        .toSet()
        .toList(growable: false);
    final knownCount = availableAssets
        .where((asset) => symbols.contains(asset.symbol))
        .length;
    if (knownCount != symbols.length) {
      return const ComparisonDateRange(
        firstDate: null,
        lastDate: null,
        hasOverlap: false,
      );
    }
    return comparisonDateRange(
      assets: availableAssets,
      selectedSymbols: symbols,
      priceHistoryMonths: 0,
    );
  }

  ({DateTime? buyDate, DateTime? sellDate}) _normalizedDates(
    List<PortfolioItem> items,
    DateTime? buyDate,
    DateTime? sellDate, {
    List<Asset>? assets,
  }) {
    if (items.isEmpty) return (buyDate: buyDate, sellDate: sellDate);
    final range = _rangeFor(items, assets: assets);
    if (!range.hasOverlap) return (buyDate: null, sellDate: null);
    DateTime? clamp(DateTime? value) {
      if (value == null) return null;
      if (range.firstDate != null && value.isBefore(range.firstDate!)) {
        return range.firstDate;
      }
      if (range.lastDate != null && value.isAfter(range.lastDate!)) {
        return range.lastDate;
      }
      return value;
    }

    final normalizedBuy = clamp(buyDate);
    var normalizedSell = clamp(sellDate);
    if (normalizedBuy != null &&
        !isValidFinancialDateRange(normalizedBuy, normalizedSell)) {
      normalizedSell = null;
    }
    return (buyDate: normalizedBuy, sellDate: normalizedSell);
  }
}
