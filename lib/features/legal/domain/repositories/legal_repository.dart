import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Yasal doküman içeriğini locale'e göre döndürür. İçerik statik (bundled);
/// network çağrısı yapmaz. Bu sayede offline'da da KVKK metni gösterilebilir
/// (yasal yükümlülük: kullanıcı her zaman erişebilmeli).
abstract class LegalRepository {
  /// [locale] kodu: `tr` veya `en`. Bilinmeyen locale'de `tr` fallback.
  LegalDocument load(LegalDocumentType type, String locale);
}
