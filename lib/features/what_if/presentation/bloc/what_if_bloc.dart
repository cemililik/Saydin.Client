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
    on<WhatIfCalculateRequested>(_onCalculateRequested);
  }

  Future<void> _onAssetsRequested(
    WhatIfAssetsRequested event,
    Emitter<WhatIfState> emit,
  ) async {
    emit(const WhatIfAssetsLoading());
    try {
      final assets = await _getAssets();
      emit(WhatIfAssetsLoaded(assets));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'get_assets');
      }
      emit(
        WhatIfFailure(assets: [], message: _messageFor(error), error: error),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'get_assets');
      emit(
        WhatIfFailure(
          assets: [],
          message: 'Bir hata oluştu. Lütfen tekrar deneyin.',
          error: UnknownError(cause: e),
        ),
      );
    }
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
      'WhatIf hesaplandı: ${event.assetSymbol} ${event.buyDate}',
      category: 'what_if',
    );

    emit(WhatIfCalculating(currentAssets));
    try {
      final result = await _calculateWhatIf(
        assetSymbol: event.assetSymbol,
        buyDate: event.buyDate,
        sellDate: event.sellDate,
        amount: event.amount,
        amountType: event.amountType,
      );
      emit(WhatIfSuccess(assets: currentAssets, result: result));
    } on DioException catch (e, st) {
      final error = _errorMapper.map(e);
      if (error is UnknownError || error is ServerError) {
        await _reporter.report(e, st, context: 'calculate_what_if');
      }
      emit(
        WhatIfFailure(
          assets: currentAssets,
          message: _messageFor(error),
          error: error,
        ),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'calculate_what_if');
      emit(
        WhatIfFailure(
          assets: currentAssets,
          message: 'Hesaplama başarısız. Lütfen tekrar deneyin.',
          error: UnknownError(cause: e),
        ),
      );
    }
  }

  String _messageFor(AppError error) => switch (error) {
    PriceNotFoundError() => 'Bu tarih için fiyat bilgisi bulunamadı.',
    DailyLimitError() => 'Günlük hesaplama limitine ulaştınız.',
    NoInternetError() => 'İnternet bağlantısı yok.',
    ServerError() => 'Sunucu hatası. Lütfen tekrar deneyin.',
    UnknownError() => 'Bir hata oluştu. Lütfen tekrar deneyin.',
  };
}
