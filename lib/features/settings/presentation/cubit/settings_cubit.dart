import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/network/language_interceptor.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const AppSettings());

  Future<void> load() async {
    final settings = await _repository.load();
    _syncLocaleHolder(settings.language);
    emit(settings);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    emit(updated);
    await _repository.save(updated);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final updated = state.copyWith(language: language);
    _syncLocaleHolder(language);
    emit(updated);
    await _repository.save(updated);
  }

  void _syncLocaleHolder(AppLanguage language) {
    AppLocaleHolder.update(switch (language) {
      AppLanguage.tr => 'tr',
      AppLanguage.en => 'en',
      AppLanguage.system => null,
    });
  }
}
