import 'package:saydin/core/network/locale_provider.dart';

import '../entities/asset.dart';
import '../repositories/what_if_repository.dart';

/// Uygulamadaki tüm finansal akışların kullandığı locale-keyed asset kataloğu.
///
/// [GetAssets] DI'da tek instance olarak yaşar. Aynı locale için eşzamanlı
/// çağrılar tek ağ Future'ını paylaşır; başarılı immutable sonuç session cache'e
/// alınır. Locale değiştiğinde yeni key doğal olarak bir kez yüklenir, eski dil
/// sonucu fallback/cache olarak birbirine karışmaz.
class GetAssets {
  final WhatIfRepository _repository;
  final LocaleProvider _localeProvider;
  final Map<String, List<Asset>> _cache = {};
  final Map<String, Future<List<Asset>>> _inFlight = {};

  GetAssets(this._repository, this._localeProvider);

  Future<List<Asset>> call({bool forceRefresh = false}) {
    final locale = _localeProvider.localeCode.toLowerCase();
    if (!forceRefresh) {
      final cached = _cache[locale];
      if (cached != null) return Future.value(cached);
    }

    final existing = _inFlight[locale];
    if (existing != null) return existing;

    final request = _load(locale);
    _inFlight[locale] = request;
    return request;
  }

  Future<List<Asset>> _load(String locale) async {
    try {
      final assets = List<Asset>.unmodifiable(await _repository.getAssets());
      _cache[locale] = assets;
      return assets;
    } finally {
      final _ = _inFlight.remove(locale);
    }
  }

  /// Test/explicit-refresh boundary. Normal locale değişimi bunu gerektirmez;
  /// yeni locale zaten ayrı cache key'idir.
  void invalidate({String? localeCode}) {
    if (localeCode == null) {
      _cache.clear();
      return;
    }
    _cache.remove(localeCode.toLowerCase());
  }
}
