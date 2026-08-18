import 'package:equatable/equatable.dart';

abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();

  /// Tanıtım akışının tamamlanma işaretini kaldırır. Yasal bildirim kaydı ayrı
  /// tutulur; onboarding yeniden tamamlandığında güncel kayıt yeniden yazılır.
  Future<void> resetOnboarding();

  /// Gösterilen legal bundle ve kullanıcının açık kararını denetlenebilir,
  /// yerel bir kayıt olarak saklar. `seen` bir kabul/rıza değildir.
  Future<void> recordLegalNotice(LegalNoticeRecord record);

  /// Kayıt yoksa veya kayıt bozuksa `null` döner; çağıran güncel metni tekrar
  /// gösterir. Eski yalnız-int acceptance anahtarı bilinçli olarak güncel kayıt
  /// sayılmaz çünkü hangi metin/locale/zamanda yazıldığı kanıtlanamaz.
  Future<LegalNoticeRecord?> getLegalNotice();
}

enum LegalNoticeDecision { seen, acknowledged }

class LegalNoticeRecord extends Equatable {
  const LegalNoticeRecord({
    required this.version,
    required this.bundleSha256,
    required this.privacyDocumentId,
    required this.kvkkDocumentId,
    required this.locale,
    required this.recordedAtUtc,
    required this.decision,
  });

  factory LegalNoticeRecord.current({
    required String locale,
    required DateTime recordedAtUtc,
    required LegalNoticeDecision decision,
  }) => LegalNoticeRecord(
    version: LegalAcceptanceVersion.current,
    bundleSha256: LegalAcceptanceVersion.bundleSha256,
    privacyDocumentId: LegalAcceptanceVersion.privacyDocumentId,
    kvkkDocumentId: LegalAcceptanceVersion.kvkkDocumentId,
    locale: locale,
    recordedAtUtc: recordedAtUtc,
    decision: decision,
  );

  final int version;
  final String bundleSha256;
  final String privacyDocumentId;
  final String kvkkDocumentId;
  final String locale;
  final DateTime recordedAtUtc;
  final LegalNoticeDecision decision;

  bool get isCurrent =>
      version == LegalAcceptanceVersion.current &&
      bundleSha256 == LegalAcceptanceVersion.bundleSha256 &&
      privacyDocumentId == LegalAcceptanceVersion.privacyDocumentId &&
      kvkkDocumentId == LegalAcceptanceVersion.kvkkDocumentId;

  @override
  List<Object?> get props => [
    version,
    bundleSha256,
    privacyDocumentId,
    kvkkDocumentId,
    locale,
    recordedAtUtc,
    decision,
  ];
}

/// KVKK / gizlilik politikası kabul sürümü sabiti. Metinler güncellendiğinde
/// (örn yasal şirket bilgileri eklendiğinde) bu sayı artırılmalı.
class LegalAcceptanceVersion {
  const LegalAcceptanceVersion._();

  /// Şu anki yasal metin sürümü. Bumped 2026-08-18.
  static const int current = 2;
  static const String privacyDocumentId = 'privacy-policy-v2-2026-08-18';
  static const String kvkkDocumentId = 'kvkk-disclosure-v2-2026-08-18';

  /// Dört TR/EN legal kaynak dosyasının deterministik bundle hash'i.
  /// `tool/verify_legal_release_approval.py --print-bundle-hash` ile üretilir.
  static const String bundleSha256 =
      'b91df0f5275fc0c457a035fbfab8a0c374c81aca02724f9a5bb109dc8da0fa0b';
}
