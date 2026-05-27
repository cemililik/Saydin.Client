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
    await _prefs.setInt(_keyLegalAcceptanceVersion, version);
  }

  @override
  Future<int?> getAcceptedLegalVersion() async {
    return _prefs.getInt(_keyLegalAcceptanceVersion);
  }
}
