import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Gizlilik Politikası — Türkçe. App Store ve Google Play yayın gereksinimidir.
/// Yer tutucu metin; yayına almadan hukuki danışmanlık alınmalıdır.
final LegalDocument privacyPolicyTr = LegalDocument(
  type: LegalDocumentType.privacyPolicy,
  title: 'Gizlilik Politikası',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Giriş',
      body:
          'Saydın olarak gizliliğinize değer veriyoruz. Bu politika, '
          'uygulamayı kullanırken hangi verilerin toplandığını, nasıl '
          'kullanıldığını ve korunduğunu açıklar.',
    ),
    LegalSection(
      heading: '2. Topladığımız Veriler',
      body:
          '• Anonim cihaz tanımlayıcısı (UUID — kullanım kotası takibi için)\n'
          '• Cihaz teknik bilgisi: işletim sistemi, uygulama versiyonu, dil\n'
          '• Yerel tercihleriniz: tema, dil, kaydedilen senaryolar\n'
          '• Hata raporları (Sentry üzerinden — kişisel veri sansürlenir)\n\n'
          'Toplamadığımız veriler: ad, soyad, e-posta, telefon, lokasyon, '
          'kişiler, fotoğraflar, finansal portföy bilgileri.',
    ),
    LegalSection(
      heading: '3. Verileri Nasıl Kullanıyoruz',
      body:
          '• Hesaplama hizmetinin sunulması\n'
          '• Tercihlerinizin saklanması\n'
          '• Hata tespiti ve uygulamanın iyileştirilmesi\n'
          '• Kötüye kullanım tespiti (rate limiting)\n\n'
          'Reklam, pazarlama veya satış amacıyla veri toplanmaz ve '
          'paylaşılmaz.',
    ),
    LegalSection(
      heading: '4. Üçüncü Taraflar',
      body:
          '• Sentry (sentry.io) — hata izleme. Tarih, tutar ve sembol gibi '
          'finansal veriler sansürlenmiş halde gönderilir.\n'
          '• Apple App Store / Google Play — uygulama dağıtımı.\n\n'
          'Bu hizmetlerin kendi gizlilik politikaları geçerlidir.',
    ),
    LegalSection(
      heading: '5. Veri Saklama',
      body:
          'Tüm yerel verileriniz cihazınızda saklanır. Sunucularımızda '
          'kullanıcıya özel veri tutulmaz; yalnızca anonim kullanım '
          'metrikleri (toplam hesaplama sayısı) tutulur.\n\n'
          'Hesabınızı sildiğinizde tüm yerel veriler anında silinir. '
          'Sentry hata raporları en geç 90 gün içinde otomatik silinir.',
    ),
    LegalSection(
      heading: '6. Güvenlik',
      body:
          '• Tüm ağ trafiği HTTPS (TLS 1.2+) üzerinden şifrelenir.\n'
          '• Cihaz tanımlayıcısı işletim sisteminin sunduğu güvenli yerel '
          'depo arayüzü ile (iOS Keychain, Android Keystore) saklanır.\n'
          '• Hata raporlarında ekran görüntüsü asla gönderilmez; tutar, '
          'tarih ve varlık bilgisi sansürlenir.',
    ),
    LegalSection(
      heading: '7. Çocukların Gizliliği',
      body:
          'Uygulama 13 yaşından küçükler için tasarlanmamıştır. 13 yaşından '
          'küçük olduğunu bildiğimiz bir kullanıcıdan veri toplamayız.',
    ),
    LegalSection(
      heading: '8. Politika Değişiklikleri',
      body:
          'Bu politika değişebilir. Önemli değişiklikler uygulama içinde '
          'duyurulur. Son güncelleme tarihi aşağıda yer alır.',
    ),
    LegalSection(
      heading: '9. İletişim',
      body: 'Sorularınız için iletisim@saydin.app adresine yazabilirsiniz.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 5, 27);
