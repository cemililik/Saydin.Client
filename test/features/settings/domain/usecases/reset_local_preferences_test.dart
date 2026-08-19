import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/domain/usecases/reset_local_preferences.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late _MockSettingsRepository settings;
  late _MockFavoritesRepository favorites;
  late _MockOnboardingRepository onboarding;
  late ResetLocalPreferences reset;

  const previousSettings = AppSettings(
    themeMode: AppThemeMode.dark,
    language: AppLanguage.en,
  );
  final previousFavorites = <String>{'BTC', 'USDTRY'};

  setUpAll(() {
    registerFallbackValue(const AppSettings());
    registerFallbackValue(<String>{});
  });

  setUp(() {
    settings = _MockSettingsRepository();
    favorites = _MockFavoritesRepository();
    onboarding = _MockOnboardingRepository();
    reset = ResetLocalPreferences(settings, favorites, onboarding);
    when(() => settings.load()).thenAnswer((_) async => previousSettings);
    when(() => favorites.load()).thenAnswer((_) async => previousFavorites);
    when(() => settings.save(any())).thenAnswer((_) async {});
    when(() => favorites.save(any())).thenAnswer((_) async {});
    when(
      () => onboarding.isOnboardingCompleted(),
    ).thenAnswer((_) async => true);
    when(() => onboarding.resetOnboarding()).thenAnswer((_) async {});
    when(() => onboarding.completeOnboarding()).thenAnswer((_) async {});
  });

  test('resets preferences and makes onboarding pending again', () async {
    await reset();

    verify(() => settings.save(const AppSettings())).called(1);
    verify(() => favorites.save(<String>{})).called(1);
    verify(() => onboarding.resetOnboarding()).called(1);
  });

  test('restores both snapshots when a reset write fails', () async {
    final resetError = StateError('favorites storage unavailable');
    var favoritesSaveCount = 0;
    when(() => favorites.save(any())).thenAnswer((_) async {
      favoritesSaveCount++;
      if (favoritesSaveCount == 1) throw resetError;
    });

    await expectLater(reset(), throwsA(same(resetError)));

    verifyInOrder([
      () => settings.save(const AppSettings()),
      () => favorites.save(<String>{}),
      () => settings.save(previousSettings),
      () => favorites.save(previousFavorites),
      () => onboarding.completeOnboarding(),
    ]);
  });

  test('restores an already-pending onboarding state as pending', () async {
    when(
      () => onboarding.isOnboardingCompleted(),
    ).thenAnswer((_) async => false);
    final resetError = StateError('favorites storage unavailable');
    var favoritesSaveCount = 0;
    when(() => favorites.save(any())).thenAnswer((_) async {
      favoritesSaveCount++;
      if (favoritesSaveCount == 1) throw resetError;
    });

    await expectLater(reset(), throwsA(same(resetError)));

    verify(() => onboarding.resetOnboarding()).called(1);
    verifyNever(() => onboarding.completeOnboarding());
  });

  test('surfaces reset and rollback failures together', () async {
    final resetError = StateError('favorites storage unavailable');
    final rollbackError = StateError('settings rollback unavailable');
    var settingsSaveCount = 0;
    when(() => settings.save(any())).thenAnswer((_) async {
      settingsSaveCount++;
      if (settingsSaveCount == 2) throw rollbackError;
    });
    var favoritesSaveCount = 0;
    when(() => favorites.save(any())).thenAnswer((_) async {
      favoritesSaveCount++;
      if (favoritesSaveCount == 1) throw resetError;
    });

    await expectLater(
      reset(),
      throwsA(
        isA<LocalPreferencesResetException>()
            .having((error) => error.resetError, 'resetError', resetError)
            .having(
              (error) => error.rollbackError,
              'rollbackError',
              rollbackError,
            ),
      ),
    );
  });
}
