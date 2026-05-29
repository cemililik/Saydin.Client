import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository _repository;
  final LocaleProvider _localeProvider;

  SettingsCubit(this._repository, this._localeProvider)
    : super(const AppSettings());

  Future<void> load() async {
    final settings = await _repository.load();
    _syncLocale(settings.language);
    emit(settings);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    emit(updated);
    await _repository.save(updated);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final updated = state.copyWith(language: language);
    _syncLocale(language);
    emit(updated);
    await _repository.save(updated);
  }

  void _syncLocale(AppLanguage language) {
    _localeProvider.update(switch (language) {
      AppLanguage.tr => 'tr',
      AppLanguage.en => 'en',
      AppLanguage.system => null,
    });
  }
}
