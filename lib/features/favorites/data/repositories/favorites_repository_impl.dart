import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  static const _key = 'favorite_symbols';

  final SharedPreferencesAsync _prefs;

  FavoritesRepositoryImpl(this._prefs);

  @override
  Future<Set<String>> load() async {
    final list = await _prefs.getStringList(_key);
    return list?.toSet() ?? {};
  }

  @override
  Future<void> save(Set<String> symbols) async {
    await _prefs.setStringList(_key, symbols.toList());
  }
}
