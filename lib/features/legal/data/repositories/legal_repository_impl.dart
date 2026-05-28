import 'package:saydin/features/legal/data/sources/kvkk_disclosure_en.dart';
import 'package:saydin/features/legal/data/sources/kvkk_disclosure_tr.dart';
import 'package:saydin/features/legal/data/sources/privacy_policy_en.dart';
import 'package:saydin/features/legal/data/sources/privacy_policy_tr.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart';

class LegalRepositoryImpl implements LegalRepository {
  const LegalRepositoryImpl();

  @override
  LegalDocument load(LegalDocumentType type, String locale) {
    // Sözleşme: EN sadece açıkça `en` ile başladığında seçilir; geri kalan
    // tüm locale'ler (TR, bilinmeyen, future locales) TR'ye düşer.
    // Türkiye ana pazar olduğu için bilinmeyen bir locale'de KVKK metnini
    // Türkçe göstermek hem yasal hem UX olarak doğru fallback.
    final isEnglish = locale.toLowerCase().startsWith('en');
    return switch (type) {
      LegalDocumentType.kvkkDisclosure =>
        isEnglish ? kvkkDisclosureEn : kvkkDisclosureTr,
      LegalDocumentType.privacyPolicy =>
        isEnglish ? privacyPolicyEn : privacyPolicyTr,
    };
  }
}
