import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';

/// Uygulama genelinde plan konfigürasyonunu tutar.
/// State doğrudan AppConfig — Loaded/Loading/Error state sınıfları gereksiz,
/// defaultConfig ile app her zaman çalışır durumda kalır.
class AppConfigCubit extends Cubit<AppConfig> {
  final AppConfigRepository _repository;

  AppConfigCubit(this._repository) : super(AppConfig.defaultConfig);

  Future<void> load() async {
    try {
      final config = await _repository.getConfig();
      emit(config);
    } catch (_) {
      // Hata durumunda defaultConfig ile çalışmaya devam et — uygulamayı bloke etme.
    }
  }
}
