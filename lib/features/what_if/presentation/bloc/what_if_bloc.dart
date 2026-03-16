import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'what_if_event.dart';
import 'what_if_state.dart';

class WhatIfBloc extends Bloc<WhatIfEvent, WhatIfState> {
  final GetAssets _getAssets;
  final CalculateWhatIf _calculateWhatIf;

  WhatIfBloc(this._getAssets, this._calculateWhatIf) : super(const WhatIfInitial()) {
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
    } on DioException catch (e) {
      emit(WhatIfFailure(assets: const [], message: _mapDioError(e)));
    } catch (_) {
      emit(WhatIfFailure(assets: [], message: 'Bir hata oluştu.'));
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
    } on DioException catch (e) {
      emit(WhatIfFailure(assets: currentAssets, message: _mapDioError(e)));
    } catch (_) {
      emit(WhatIfFailure(assets: currentAssets, message: 'Hesaplama başarısız.'));
    }
  }

  String _mapDioError(DioException e) {
    if (e.response?.statusCode == 404) return 'Bu tarih için fiyat bilgisi bulunamadı.';
    if (e.response?.statusCode == 429) return 'Günlük hesaplama limitine ulaştınız.';
    if (e.type == DioExceptionType.connectionError) return 'İnternet bağlantısı yok.';
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
