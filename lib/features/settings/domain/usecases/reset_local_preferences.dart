import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';

/// Yalnız bu cihazdaki kullanıcı tercihlerini başlangıç değerlerine döndürür.
///
/// Hesap, cihaz kimliği, legal bildirim kaydı ve sunucudaki senaryolar bu
/// işlemin kapsamı dışındadır. Onboarding tamamlanma işareti kaldırılır. Çağıran,
/// başarılı yazımdan sonra session widget ağacını yeniden kurarak onboarding'i
/// gösterir ve açık form/sonuç state'lerini temizler.
class ResetLocalPreferences {
  const ResetLocalPreferences(
    this._settings,
    this._favorites,
    this._onboarding,
  );

  final SettingsRepository _settings;
  final FavoritesRepository _favorites;
  final OnboardingRepository _onboarding;

  Future<void> call() async {
    // Üç ayrı storage yazımı atomik değildir. Önce mevcut değerleri snapshot
    // alıp herhangi bir hata halinde best-effort compensation uygularız;
    // başarılı olmayan bir reset yarım kalmış tercihler bırakmasın.
    final previousSettings = await _settings.load();
    final previousFavorites = await _favorites.load();
    final previousOnboardingCompleted = await _onboarding
        .isOnboardingCompleted();

    try {
      await _settings.save(const AppSettings());
      await _favorites.save(const <String>{});
      await _onboarding.resetOnboarding();
    } catch (error, stackTrace) {
      Object? rollbackError;
      try {
        await _settings.save(previousSettings);
      } catch (error) {
        rollbackError = error;
      }
      try {
        await _favorites.save(previousFavorites);
      } catch (error) {
        rollbackError ??= error;
      }
      try {
        if (previousOnboardingCompleted) {
          await _onboarding.completeOnboarding();
        } else {
          await _onboarding.resetOnboarding();
        }
      } catch (error) {
        rollbackError ??= error;
      }

      if (rollbackError != null) {
        throw LocalPreferencesResetException(
          resetError: error,
          rollbackError: rollbackError,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class LocalPreferencesResetException implements Exception {
  const LocalPreferencesResetException({
    required this.resetError,
    required this.rollbackError,
  });

  final Object resetError;
  final Object rollbackError;

  @override
  String toString() =>
      'Local preferences reset and rollback both failed: '
      'reset=$resetError, rollback=$rollbackError';
}
