import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';

enum SettingsPersistenceFeedback { saveFailed }

class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository _repository;
  final LocaleProvider _localeProvider;
  final ErrorReporter _reporter;
  final _feedbackController =
      StreamController<SettingsPersistenceFeedback>.broadcast();

  SettingsCubit(
    this._repository,
    this._localeProvider, {
    ErrorReporter? reporter,
  }) : _reporter = reporter ?? const ErrorReporter(),
       super(const AppSettings());

  /// Kalıcı yazma hatalarını kullanıcı arayüzüne bir kez iletir.
  ///
  /// Ayarlar state'i başarılı olarak kaydedilmiş tercihleri temsil etmeye devam
  /// eder; geçici hata state'i eklemek yerine bu kısa ömürlü kanal kullanılır.
  Stream<SettingsPersistenceFeedback> get feedbacks =>
      _feedbackController.stream;

  /// F-12-21: depo okuması (SharedPreferences) çökerse uygulama açılışta
  /// crash etmesin — hatayı raporla ve güvenli varsayılan ([AppSettings] +
  /// sistem locale'i) ile devam et. Sessiz `catch` yoktur; her hata
  /// observability'ye gider.
  Future<void> load() async {
    try {
      final settings = await _repository.load();
      _syncLocale(settings.language);
      if (isClosed) return;
      emit(settings);
    } catch (e, st) {
      await _reporter.report(e, st, context: 'settings_load');
      // Initial state zaten güvenli varsayılan; locale'i de ona hizala.
      _syncLocale(state.language);
    }
  }

  /// F-12-13: önce kalıcı yaz, **sonra** emit — atomiklik. Eski sürüm önce
  /// emit edip sonra kaydediyordu; yazma başarısız olursa UI tema değişmiş
  /// ama disk eski kalıyordu (tutarsızlık + sessiz yutma). Artık yazma
  /// başarısızsa state değişmez ve hata raporlanır.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    try {
      await _repository.save(updated);
      if (isClosed) return;
      emit(updated);
    } catch (e, st) {
      await _reporter.report(e, st, context: 'settings_set_theme');
      if (!isClosed) {
        _feedbackController.add(SettingsPersistenceFeedback.saveFailed);
      }
    }
  }

  /// Dil değişimi de tema ile aynı atomik kalıbı izler (F-12-13): yazma
  /// başarılıysa locale senkronlanır + emit edilir; başarısızsa state ve
  /// locale değişmez, hata raporlanır.
  Future<void> setLanguage(AppLanguage language) async {
    final updated = state.copyWith(language: language);
    try {
      await _repository.save(updated);
      if (isClosed) return;
      _syncLocale(language);
      emit(updated);
    } catch (e, st) {
      await _reporter.report(e, st, context: 'settings_set_language');
      if (!isClosed) {
        _feedbackController.add(SettingsPersistenceFeedback.saveFailed);
      }
    }
  }

  void _syncLocale(AppLanguage language) {
    _localeProvider.update(switch (language) {
      AppLanguage.tr => 'tr',
      AppLanguage.en => 'en',
      AppLanguage.system => null,
    });
  }

  @override
  Future<void> close() async {
    await _feedbackController.close();
    return super.close();
  }
}
