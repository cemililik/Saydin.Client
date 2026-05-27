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
    final isTr = locale.toLowerCase().startsWith('tr');
    return switch (type) {
      LegalDocumentType.kvkkDisclosure =>
        isTr ? kvkkDisclosureTr : kvkkDisclosureEn,
      LegalDocumentType.privacyPolicy =>
        isTr ? privacyPolicyTr : privacyPolicyEn,
    };
  }
}
