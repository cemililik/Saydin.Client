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
    on<PortfolioItemRemoved>(_onItemRemoved);
    on<PortfolioCalculateRequested>(_onCalculateRequested);
    on<PortfolioReset>(_onReset);
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
      ),
    );
    try {
      final result = await _calculatePortfolio(
        items: state.items,
        buyDate: state.buyDate!,
        sellDate: state.sellDate,
      );
      emit(
        PortfolioSuccess(
          assets: state.assets,
          items: state.items,
          buyDate: state.buyDate,
          sellDate: state.sellDate,
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
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  void _onReset(PortfolioReset event, Emitter<PortfolioState> emit) {
    emit(PortfolioEditing(assets: state.assets));
  }
}
