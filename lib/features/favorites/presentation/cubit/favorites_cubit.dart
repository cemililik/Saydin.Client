import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesCubit extends Cubit<Set<String>> {
  static const maxFavorites = 5;

  final FavoritesRepository _repository;

  FavoritesCubit(this._repository) : super(const {});

  Future<void> load() async {
    final favorites = await _repository.load();
    emit(favorites);
  }

  Future<void> toggle(String symbol) async {
    final updated = Set<String>.from(state);
    if (updated.contains(symbol)) {
      updated.remove(symbol);
    } else {
      if (updated.length >= maxFavorites) return;
      updated.add(symbol);
    }
    emit(updated);
    await _repository.save(updated);
  }

  bool isFavorite(String symbol) => state.contains(symbol);

  bool get isFull => state.length >= maxFavorites;
}
