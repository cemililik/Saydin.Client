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
      // Türkçe ip ucu: veri sorumlusu alanı görünür ve fail-closed olmalı.
      expect(doc.sections.first.body, contains('Veri sorumlusunun'));
    });

    test('İngilizce locale için İngilizce KVKK döner', () {
      final doc = repo.load(LegalDocumentType.kvkkDisclosure, 'en_US');
      expect(doc.title, contains('KVKK'));
      expect(
        doc.sections.first.body,
        contains("controller's official legal name"),
      );
    });

    test('Bilinmeyen locale için TR fallback (sözleşme: only en → EN)', () {
      // Sözleşme: `en` prefix ile başlamayan her locale TR'ye düşer.
      // 'fr_FR' → TR (Türkiye ana pazar; bilinmeyen locale'de yasal metin
      // Türkçe daha doğru fallback).
      final doc = repo.load(LegalDocumentType.privacyPolicy, 'fr_FR');
      expect(doc.title, startsWith('Gizlilik Politikası'));
    });

    test('Sadece `en` prefix EN seçer (en, en_US, en_GB)', () {
      for (final loc in ['en', 'en_US', 'en_GB', 'EN']) {
        final doc = repo.load(LegalDocumentType.privacyPolicy, loc);
        expect(doc.title, startsWith('Privacy Policy'), reason: 'locale=$loc');
      }
    });

    test('Türkçe locale için Türkçe Privacy döner', () {
      final doc = repo.load(LegalDocumentType.privacyPolicy, 'tr');
      expect(doc.title, startsWith('Gizlilik Politikası'));
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

    test('TR ve EN doküman yapıları ve tarihleri paralel kalır', () {
      for (final type in LegalDocumentType.values) {
        final tr = repo.load(type, 'tr');
        final en = repo.load(type, 'en');

        expect(en.sections.length, tr.sections.length, reason: '$type');
        expect(en.lastUpdated, tr.lastUpdated, reason: '$type');
        expect(
          tr.sections.map((section) => section.heading.split('.').first),
          en.sections.map((section) => section.heading.split('.').first),
          reason: '$type section sırası farklı',
        );
      }
    });

    test('onaysız metinlerin yayın taslağı olduğu görünür kalır', () {
      for (final type in LegalDocumentType.values) {
        final tr = repo.load(type, 'tr');
        final en = repo.load(type, 'en');

        expect(tr.title, contains('Yayın Taslağı'), reason: '$type / tr');
        expect(en.title, contains('Publication Draft'), reason: '$type / en');
        expect(_body(tr), contains('yayınlanmamalıdır'), reason: '$type / tr');
        expect(
          _body(en),
          contains('must not be published'),
          reason: '$type / en',
        );
      }
    });

    test('teknik veri envanteri iki dilde ve iki metinde açıklanır', () {
      for (final type in LegalDocumentType.values) {
        final tr = _body(repo.load(type, 'tr')).toLowerCase();
        final en = _body(repo.load(type, 'en')).toLowerCase();

        for (final requiredText in [
          'takma adlı',
          'hesaplama girdileri',
          'api sunucusuna',
          'sentry',
          'ios keychain',
          'yeniden denenebilir',
          '200 veya 204',
          'yalnızca fotoğraf kütüphanesine ekleme izni',
          'performans izleme kapalıdır',
          'otomatik oturum takibi',
          'hukuki bildirimden önce',
          'store release buildleri',
          'session replay',
        ]) {
          expect(tr, contains(requiredText), reason: '$type / tr');
        }
        for (final requiredText in [
          'pseudonymous',
          'calculation inputs',
          'api server',
          'sentry',
          'ios keychain',
          'same identity',
          '200 or 204',
          'add-only photo',
          'performance tracing are disabled',
          'automatic session tracking',
          'before the app ui and legal notice',
          'store release builds',
          'session replay',
        ]) {
          expect(en, contains(requiredText), reason: '$type / en');
        }
      }
    });

    test('doğrulanmamış eski mutlak privacy iddiaları geri eklenmez', () {
      final allText = [
        for (final type in LegalDocumentType.values)
          for (final locale in ['tr', 'en'])
            '${repo.load(type, locale).title}\n${_body(repo.load(type, locale))}',
      ].join('\n').toLowerCase();

      for (final forbiddenText in [
        'anonim cihaz tanımlayıcısı',
        'anonymous device identifier',
        'sunucularımızda kullanıcıya özel veri tutulmaz',
        'no user-specific data is kept on our servers',
        'uygulamayı kaldırdığınızda silinir',
        'deleted when you uninstall the app',
        'kişisel veri sansürlenir',
        'personal data is scrubbed',
        '90 gün',
        '90 days',
      ]) {
        expect(allText, isNot(contains(forbiddenText)), reason: forbiddenText);
      }
    });

    test('sistem paylaşım hedefinin ayrı alıcı olduğu iki dilde açıklanır', () {
      for (final type in LegalDocumentType.values) {
        final tr = _body(repo.load(type, 'tr')).toLowerCase();
        final en = _body(repo.load(type, 'en')).toLowerCase();

        expect(tr, contains('sistem paylaşım'), reason: '$type / tr');
        expect(tr, contains('ayrı alıcı'), reason: '$type / tr');
        expect(en, contains('system share'), reason: '$type / en');
        expect(en, contains('separate recipient'), reason: '$type / en');
      }
    });
  });
}

String _body(LegalDocument document) => document.sections
    .map((section) => '${section.heading}\n${section.body}')
    .join('\n');
