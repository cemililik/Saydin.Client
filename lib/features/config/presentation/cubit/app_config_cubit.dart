import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';

/// Uygulama genelinde plan konfigürasyonunu tutar.
/// State doğrudan AppConfig — Loaded/Loading/Error state sınıfları gereksiz,
/// defaultConfig ile app her zaman çalışır durumda kalır.
class AppConfigCubit extends Cubit<AppConfig> {
  final AppConfigRepository _repository;
  final ErrorReporter _reporter;

  AppConfigCubit(this._repository, {ErrorReporter? reporter})
    : _reporter = reporter ?? const ErrorReporter(),
      super(AppConfig.defaultConfig);

  Future<void> load() async {
    try {
      final config = await _repository.getConfig();
      emit(config);
    } catch (e, st) {
      // Hata durumunda defaultConfig ile çalışmaya devam et — uygulamayı bloke
      // etme. Ancak sessiz catch sürekli config endpoint hatalarını gizlerdi.
      // KVKK Madde 12 (veri güvenliği) ve paywall semantiği açısından bu
      // hatanın observability'ye gitmesi gerekir; downgrade ya kasıtsız MITM
      // ya da config endpoint regresyonu olabilir.
      await _reporter.report(e, st, context: 'app_config_load');
    }
  }
}
