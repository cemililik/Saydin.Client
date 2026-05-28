abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();

  /// KVKK aydınlatma metninin / gizlilik politikasının hangi sürümünün
  /// kullanıcı tarafından implicit olarak (onboarding "Hemen Dene"
  /// butonuna basarak) kabul edildiğini kaydeder.
  ///
  /// Yasal metinler güncellendiğinde [LegalAcceptanceVersion.current]
  /// artırılmalı; kullanıcı uygulama açtığında metinlerin yeni sürümü
  /// gösterilmelidir (ileride implement edilecek).
  Future<void> recordLegalAcceptance(int version);

  /// Kullanıcının kabul ettiği en son legal metin sürümü. Henüz hiç kabul
  /// edilmediyse `null` döner.
  Future<int?> getAcceptedLegalVersion();
}

/// KVKK / gizlilik politikası kabul sürümü sabiti. Metinler güncellendiğinde
/// (örn yasal şirket bilgileri eklendiğinde) bu sayı artırılmalı.
class LegalAcceptanceVersion {
  const LegalAcceptanceVersion._();

  /// Şu anki yasal metin sürümü. Bumped 2026-05-27.
  static const int current = 1;
}
