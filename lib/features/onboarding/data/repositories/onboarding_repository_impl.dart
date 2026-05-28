import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyLegalAcceptanceVersion = 'legal_acceptance_version';

  final SharedPreferencesAsync _prefs;

  OnboardingRepositoryImpl(this._prefs);

  @override
  Future<bool> isOnboardingCompleted() async {
    return await _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  @override
  Future<void> recordLegalAcceptance(int version) async {
    // Sürüm numarası 1'den başlar; 0/negatif değerler consent state'i
    // bozar (örn `getAcceptedLegalVersion == 0` "kabul edildi" mi yoksa
    // "hiç kabul edilmedi" mi belirsiz). Erken fail edip kontamine veriyi
    // engelle.
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'Legal acceptance version must be >= 1',
      );
    }
    await _prefs.setInt(_keyLegalAcceptanceVersion, version);
  }

  @override
  Future<int?> getAcceptedLegalVersion() async {
    return _prefs.getInt(_keyLegalAcceptanceVersion);
  }
}
