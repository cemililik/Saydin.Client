import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:uuid/uuid.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final GetAssets _getAssets;
  final CalculatePortfolio _calculatePortfolio;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  static const _uuid = Uuid();

  PortfolioBloc(
    this._getAssets,
    this._calculatePortfolio, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter,
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
    if (state.assets.isNotEmpty) return;
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
      emit(
        PortfolioEditing(
          assets: assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'portfolio_get_assets');
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
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: state.items,
        buyDate: event.date,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onSellDateChanged(
    PortfolioSellDateChanged event,
    Emitter<PortfolioState> emit,
  ) {
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
    final newItem = PortfolioItem(
      id: _uuid.v4(),
      assetSymbol: event.assetSymbol,
      assetDisplayName: event.assetDisplayName,
      amount: event.amount,
      amountType: event.amountType,
    );
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: [...state.items, newItem],
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onItemUpdated(
    PortfolioItemUpdated event,
    Emitter<PortfolioState> emit,
  ) {
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

    emit(
      PortfolioEditing(
        assets: state.assets,
        items: updatedItems,
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  void _onItemRemoved(
    PortfolioItemRemoved event,
    Emitter<PortfolioState> emit,
  ) {
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: state.items.where((i) => i.id != event.id).toList(),
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
  }

  Future<void> _onCalculateRequested(
    PortfolioCalculateRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(
      PortfolioCalculating(
        assets: state.assets,
        items: state.items,
        buyDate: state.buyDate,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      ),
    );
    try {
      final result = await _calculatePortfolio(
        items: state.items,
        buyDate: state.buyDate!,
        sellDate: state.sellDate,
        includeInflation: state.includeInflation,
      );
      emit(
        PortfolioSuccess(
          assets: state.assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          result: result,
        ),
      );
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'portfolio_calculate');
      }
      emit(
        PortfolioFailure(
          assets: state.assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          error: error,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'portfolio_calculate');
      emit(
        PortfolioFailure(
          assets: state.assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
          includeInflation: state.includeInflation,
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  void _onInflationToggled(
    PortfolioInflationToggled event,
    Emitter<PortfolioState> emit,
  ) {
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
    emit(PortfolioEditing(assets: state.assets));
  }

  Future<void> _onReplayRequested(
    PortfolioReplayRequested event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(
      PortfolioEditing(
        assets: state.assets,
        items: event.items,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        includeInflation: event.includeInflation,
      ),
    );
    if (event.items.isNotEmpty) {
      await _onCalculateRequested(const PortfolioCalculateRequested(), emit);
    }
  }

  Future<void> _onLanguageChanged(
    PortfolioLanguageChanged event,
    Emitter<PortfolioState> emit,
  ) async {
    // Form state'i ve önceki hesaplama sonucunu kaydet
    final savedItems = state.items;
    final savedBuyDate = state.buyDate;
    final savedSellDate = state.sellDate;
    final savedInflation = state.includeInflation;
    final hadResult = state is PortfolioSuccess;

    try {
      final assets = await _getAssets();

      if (hadResult && savedItems.isNotEmpty && savedBuyDate != null) {
        emit(
          PortfolioCalculating(
            assets: assets,
            items: savedItems,
            buyDate: savedBuyDate,
            sellDate: savedSellDate,
            includeInflation: savedInflation,
          ),
        );
        try {
          final result = await _calculatePortfolio(
            items: savedItems,
            buyDate: savedBuyDate,
            sellDate: savedSellDate,
            includeInflation: savedInflation,
          );
          emit(
            PortfolioSuccess(
              assets: assets,
              items: savedItems,
              buyDate: savedBuyDate,
              sellDate: savedSellDate,
              includeInflation: savedInflation,
              result: result,
            ),
          );
        } catch (_) {
          emit(
            PortfolioEditing(
              assets: assets,
              items: savedItems,
              buyDate: savedBuyDate,
              sellDate: savedSellDate,
              includeInflation: savedInflation,
            ),
          );
        }
      } else {
        emit(
          PortfolioEditing(
            assets: assets,
            items: savedItems,
            buyDate: savedBuyDate,
            sellDate: savedSellDate,
            includeInflation: savedInflation,
          ),
        );
      }
    } catch (_) {
      // Asset fetch başarısız — mevcut state'i koru
    }
  }
}
