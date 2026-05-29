import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockLocaleProvider extends Mock implements LocaleProvider {}

class MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late MockSettingsRepository repo;
  late MockLocaleProvider localeProvider;
  late MockErrorReporter reporter;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    repo = MockSettingsRepository();
    localeProvider = MockLocaleProvider();
    reporter = MockErrorReporter();
    when(() => repo.load()).thenAnswer((_) async => const AppSettings());
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(
      () => reporter.report(
        any(),
        any(),
        context: any(named: 'context'),
        extras: any(named: 'extras'),
      ),
    ).thenAnswer((_) async {});
  });

  // F-12-17 + F-05-27: dil senkronu artık global static AppLocaleHolder yerine
  // DI ile enjekte edilen LocaleProvider üzerinden — bu sayede test izole
  // edilebilir (sahte provider'a verify yapılır, global state mutasyonu yok).

  test('load: kaydedilmiş dil LocaleProvider\'a senkronlanır', () async {
    when(
      () => repo.load(),
    ).thenAnswer((_) async => const AppSettings(language: AppLanguage.en));

    final cubit = SettingsCubit(repo, localeProvider);
    await cubit.load();

    verify(() => localeProvider.update('en')).called(1);
    expect(cubit.state.language, AppLanguage.en);
  });

  test('setLanguage(tr): LocaleProvider güncellenir + state emit', () async {
    final cubit = SettingsCubit(repo, localeProvider);

    await cubit.setLanguage(AppLanguage.tr);

    verify(() => localeProvider.update('tr')).called(1);
    verify(() => repo.save(any())).called(1);
    expect(cubit.state.language, AppLanguage.tr);
  });

  test('setLanguage(system): LocaleProvider.update(null)', () async {
    final cubit = SettingsCubit(repo, localeProvider);

    await cubit.setLanguage(AppLanguage.system);

    verify(() => localeProvider.update(null)).called(1);
  });

  test('setThemeMode: locale provider\'a dokunmaz', () async {
    final cubit = SettingsCubit(repo, localeProvider);

    await cubit.setThemeMode(AppThemeMode.dark);

    verifyNever(() => localeProvider.update(any()));
    expect(cubit.state.themeMode, AppThemeMode.dark);
  });

  // F-12-21: depo okuması çökerse crash etme, raporla, güvenli varsayılanda kal.
  test(
    'load: hata fırlatırsa crash etmez, raporlar, varsayılanda kalır',
    () async {
      when(() => repo.load()).thenThrow(Exception('storage broken'));

      final cubit = SettingsCubit(repo, localeProvider, reporter: reporter);
      await cubit.load();

      expect(cubit.state, const AppSettings());
      verify(
        () => reporter.report(any(), any(), context: 'settings_load'),
      ).called(1);
    },
  );

  // F-12-13: yazma başarısızsa state DEĞİŞMEZ (atomiklik) ve hata raporlanır.
  test(
    'setThemeMode: save fail → emit yok, rapor var, state korunur',
    () async {
      when(() => repo.save(any())).thenThrow(Exception('disk full'));

      final cubit = SettingsCubit(repo, localeProvider, reporter: reporter);
      await cubit.setThemeMode(AppThemeMode.dark);

      expect(cubit.state.themeMode, const AppSettings().themeMode);
      verify(
        () => reporter.report(any(), any(), context: 'settings_set_theme'),
      ).called(1);
    },
  );

  test(
    'setLanguage: save fail → locale dokunulmaz, rapor var, state korunur',
    () async {
      when(() => repo.save(any())).thenThrow(Exception('disk full'));

      final cubit = SettingsCubit(repo, localeProvider, reporter: reporter);
      await cubit.setLanguage(AppLanguage.en);

      expect(cubit.state.language, const AppSettings().language);
      verifyNever(() => localeProvider.update(any()));
      verify(
        () => reporter.report(any(), any(), context: 'settings_set_language'),
      ).called(1);
    },
  );
}
