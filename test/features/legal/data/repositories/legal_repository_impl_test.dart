import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/legal/data/repositories/legal_repository_impl.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';

void main() {
  const repo = LegalRepositoryImpl();

  group('LegalRepositoryImpl', () {
    test('Türkçe locale için Türkçe KVKK döner', () {
      final doc = repo.load(LegalDocumentType.kvkkDisclosure, 'tr_TR');
      expect(doc.type, LegalDocumentType.kvkkDisclosure);
      expect(doc.title, contains('KVKK'));
      expect(doc.sections, isNotEmpty);
      // Türkçe ip ucu: "Veri Sorumlusu"
      expect(doc.sections.first.body, contains('Veri Sorumlusu'));
    });

    test('İngilizce locale için İngilizce KVKK döner', () {
      final doc = repo.load(LegalDocumentType.kvkkDisclosure, 'en_US');
      expect(doc.title, contains('KVKK'));
      // EN için: "Data Controller"
      expect(doc.sections.first.body, contains('Data Controller'));
    });

    test('Bilinmeyen locale için TR fallback (sözleşme: only en → EN)', () {
      // Sözleşme: `en` prefix ile başlamayan her locale TR'ye düşer.
      // 'fr_FR' → TR (Türkiye ana pazar; bilinmeyen locale'de yasal metin
      // Türkçe daha doğru fallback).
      final doc = repo.load(LegalDocumentType.privacyPolicy, 'fr_FR');
      expect(doc.title, 'Gizlilik Politikası');
    });

    test('Sadece `en` prefix EN seçer (en, en_US, en_GB)', () {
      for (final loc in ['en', 'en_US', 'en_GB', 'EN']) {
        final doc = repo.load(LegalDocumentType.privacyPolicy, loc);
        expect(doc.title, 'Privacy Policy', reason: 'locale=$loc');
      }
    });

    test('Türkçe locale için Türkçe Privacy döner', () {
      final doc = repo.load(LegalDocumentType.privacyPolicy, 'tr');
      expect(doc.title, 'Gizlilik Politikası');
      expect(doc.sections.first.body, contains('Saydın'));
    });

    test('lastUpdated UTC tarih içerir', () {
      final doc = repo.load(LegalDocumentType.kvkkDisclosure, 'tr');
      expect(doc.lastUpdated.isUtc, isTrue);
    });

    test('Tüm dokümanlar boş olmayan section listesine sahip', () {
      for (final type in LegalDocumentType.values) {
        for (final locale in ['tr', 'en']) {
          final doc = repo.load(type, locale);
          expect(
            doc.sections,
            isNotEmpty,
            reason: '$type / $locale boş section döndü',
          );
          for (final section in doc.sections) {
            expect(section.heading, isNotEmpty);
            expect(section.body, isNotEmpty);
          }
        }
      }
    });
  });
}
