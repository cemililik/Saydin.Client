import 'package:equatable/equatable.dart';

/// Yasal metin türü. `LegalRepository.load(type, locale)` ile içeriği çekilir.
enum LegalDocumentType {
  /// KVKK 6698 Madde 10 — aydınlatma yükümlülüğü.
  kvkkDisclosure,

  /// Gizlilik politikası — hangi veriler, nasıl, ne amaçla işleniyor.
  privacyPolicy,
}

/// Locale bağımsız yasal doküman. Sadece presentation katmanı için —
/// içerik kaynağı `data/sources/` altında locale'e göre seçilir.
class LegalDocument extends Equatable {
  const LegalDocument({
    required this.type,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final LegalDocumentType type;
  final String title;
  final DateTime lastUpdated;
  final List<LegalSection> sections;

  @override
  List<Object?> get props => [type, title, lastUpdated, sections];
}

class LegalSection extends Equatable {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  List<Object?> get props => [heading, body];
}
