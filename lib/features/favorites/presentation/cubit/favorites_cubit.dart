import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  static const maxFavorites = 5;

  final FavoritesRepository _repository;
  final ErrorReporter _reporter;

  FavoritesCubit(this._repository, {ErrorReporter? reporter})
    : _reporter = reporter ?? const ErrorReporter(),
      super(const {});

  Future<void> load() async {
    try {
      final favorites = await _repository.load();
      if (isClosed) return;
      emit(favorites);
    } catch (e, st) {
      // Yükleme başarısızsa boş favori setiyle devam et (initial state) —
      // ama sessizce yutma; observability'ye gönder.
      await _reporter.report(e, st, context: 'favorites_load');
    }
  }

  /// F-11-10: optimistic toggle. Önce UI güncellenir (anlık geri bildirim);
  /// kalıcı yazma başarısız olursa **eski state'e geri dönülür** (rollback)
  /// ve hata raporlanır. State `Set<String>` olduğundan ayrı bir hata-state'i
  /// yerine rollback + observability tercih edildi: yıldız eski haline döner,
  /// bu kullanıcıya "işlem kaydedilmedi" sinyalidir; hata da Sentry'ye gider
  /// (eski sürüm yazma hatasını sessizce yutuyordu).
  Future<void> toggle(String symbol) async {
    final previous = state;
    final updated = Set<String>.from(previous);
    if (updated.contains(symbol)) {
      updated.remove(symbol);
    } else {
      if (updated.length >= maxFavorites) return;
      updated.add(symbol);
    }
    emit(updated);
    try {
      await _repository.save(updated);
    } catch (e, st) {
      if (isClosed) return;
      // Yarış koruması: yalnızca bu toggle'ın iyimser değeri HÂLÂ güncel state
      // ise geri al. Kullanıcı hızlı ardı ardına bastıysa, bu çağrının `save`'i
      // beklerken araya başka bir (başarılı) toggle girmiş olabilir; o zaman
      // stale `previous`'a rollback, sonraki toggle'ı EZERDİ (state bozulması).
      // `identical` ile araya emit girip girmediğini kontrol et — girmişse
      // rollback'i atla (en güncel niyet kazanır), hata yine raporlanır.
      if (identical(state, updated)) emit(previous);
      await _reporter.report(e, st, context: 'favorites_toggle');
    }
  }

  bool isFavorite(String symbol) => state.contains(symbol);

  bool get isFull => state.length >= maxFavorites;
}
