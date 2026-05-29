import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late MockPrefs prefs;
  late SettingsRepositoryImpl repo;

  setUp(() {
    prefs = MockPrefs();
    repo = SettingsRepositoryImpl(prefs);
  });

  group('SettingsRepositoryImpl (F-12-04 enum.name + migration)', () {
    test('save: ordinal index DEĞİL, enum.name (string) yazar', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async {});

      await repo.save(
        const AppSettings(
          themeMode: AppThemeMode.dark,
          language: AppLanguage.en,
        ),
      );

      verify(() => prefs.setString('settings_theme_mode', 'dark')).called(1);
      verify(() => prefs.setString('settings_language', 'en')).called(1);
    });

    test('load: yeni string formatını doğru enum\'a çözer', () async {
      when(
        () => prefs.getString('settings_theme_mode'),
      ).thenAnswer((_) async => 'dark');
      when(
        () => prefs.getString('settings_language'),
      ).thenAnswer((_) async => 'en');

      final s = await repo.load();

      expect(s.themeMode, AppThemeMode.dark);
      expect(s.language, AppLanguage.en);
    });

    test(
      'migration: legacy int (getString null, getInt index) → enum + tek-seferlik rewrite',
      () async {
        when(() => prefs.getString(any())).thenAnswer((_) async => null);
        when(
          () => prefs.getInt('settings_theme_mode'),
        ).thenAnswer((_) async => AppThemeMode.dark.index);
        when(
          () => prefs.getInt('settings_language'),
        ).thenAnswer((_) async => AppLanguage.en.index);
        when(() => prefs.setString(any(), any())).thenAnswer((_) async {});

        final s = await repo.load();

        expect(s.themeMode, AppThemeMode.dark);
        expect(s.language, AppLanguage.en);
        // legacy int yeni string formatında yeniden yazılır
        verify(() => prefs.setString('settings_theme_mode', 'dark')).called(1);
        verify(() => prefs.setString('settings_language', 'en')).called(1);
      },
    );

    test('getString tip-uyuşmazlığı atarsa legacy int yoluna düşer', () async {
      when(() => prefs.getString(any())).thenThrow(Exception('type mismatch'));
      when(
        () => prefs.getInt('settings_theme_mode'),
      ).thenAnswer((_) async => AppThemeMode.light.index);
      when(
        () => prefs.getInt('settings_language'),
      ).thenAnswer((_) async => AppLanguage.tr.index);
      when(() => prefs.setString(any(), any())).thenAnswer((_) async {});

      final s = await repo.load();

      expect(s.themeMode, AppThemeMode.light);
      expect(s.language, AppLanguage.tr);
    });

    test('eksik/bilinmeyen değer → default (system)', () async {
      when(() => prefs.getString(any())).thenAnswer((_) async => null);
      when(() => prefs.getInt(any())).thenAnswer((_) async => null);

      final s = await repo.load();

      expect(s.themeMode, AppThemeMode.system);
      expect(s.language, AppLanguage.system);
    });

    test('out-of-range legacy index → default (system), crash yok', () async {
      when(() => prefs.getString(any())).thenAnswer((_) async => null);
      when(() => prefs.getInt(any())).thenAnswer((_) async => 99);

      final s = await repo.load();

      expect(s.themeMode, AppThemeMode.system);
      expect(s.language, AppLanguage.system);
    });
  });
}
