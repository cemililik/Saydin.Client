import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Uygulamanın mevcut teknik veri akışıyla eşleştirilmiş Türkçe taslak.
///
/// Bu metin yayın için onaylanmış bir hukuk metni değildir. Veri sorumlusunun
/// resmî kimliği ve adresi, veri işleme şartları, alıcı/ülke listesi, aktarım
/// mekanizması ile saklama-imha süreleri `docs/legal/legal-release-signoff.md`
/// tamamlanıp hukuk/DPO onayı alınmadan uygulama mağazasına gönderilmemelidir.
final LegalDocument privacyPolicyTr = LegalDocument(
  type: LegalDocumentType.privacyPolicy,
  title: 'Gizlilik Politikası — Yayın Taslağı',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Durum ve Kapsam',
      body:
          'Bu taslak, Saydın mobil uygulamasının mevcut istemci kodunda '
          'gözlemlenen veri akışlarını açıklar; yayın için onaylanmış nihai '
          'politika değildir. Veri sorumlusunun resmî kimliği ve adresi, '
          'işleme şartları, hizmet sağlayıcıları, aktarım yerleri ve gerçek '
          'saklama süreleri doğrulanmadan uygulama yayınlanmamalıdır.',
    ),
    LegalSection(
      heading: '2. İşlenen Veri Kategorileri',
      body:
          'Uygulama ve hizmet altyapısı aşağıdaki verileri işler:\n\n'
          '• Her API isteğine eklenen kalıcı, takma adlı (psödonim) cihaz '
          'tanımlayıcısı; kullanım kotası ve tekrar tespiti için kullanılır. '
          'Bu tanımlayıcı anonim veri değildir.\n'
          '• İşletim sistemi ve azaltılmış sürüm bilgisi, uygulama sürümü ve '
          'seçili/sistem dili gibi teknik bilgiler.\n'
          '• Hesaplama girdileri: varlık sembolü ve adı, tutar, tutar türü, '
          'tarih aralığı, dönem, enflasyon seçimi ve karşılaştırma veya '
          'portföy bileşenleri.\n'
          '• Kaydetmeyi seçtiğiniz senaryolar: yukarıdaki girdiler, senaryo '
          'türü, sunucu kimliği, oluşturulma zamanı ve senaryoya özgü ek '
          'alanlar.\n'
          '• Cihazdaki tercihler: tema, dil, favori semboller ve onboarding '
          'durumu; ayrıca gösterilen hukuki metin bundle sürümü/hash’i, belge '
          'kimlikleri, gösterim dili ve UTC zamanı ile bildirimin yalnız '
          'görüldüğünü veya isteğe bağlı olarak işaretlendiğini belirten kayıt.\n'
          '• Mağaza için üretilen sürümlerde Sentry hata/çökme telemetrisi '
          'etkindir; DSN verilmeyen yerel/test sürümlerinde kapalıdır. Sentry '
          'uygulama arayüzü ve hukuki bildirimden önce başlatıldığı için '
          'başlangıç ile bildirim gösterim/kayıt hataları da işlenebilir. '
          'Teknik eylem izleri ve uygulama/işletim sistemi sürümü işlenebilir. '
          'Ekran görüntüsü, session replay, otomatik oturum takibi ve performans izleme '
          'kapalıdır. Dart hata olayları gönderilmeden önce filtrelenir; '
          'filtreleme native crash zarfı için doğrulanmış garanti değildir.',
    ),
    LegalSection(
      heading: '3. Verilerin Kullanım Amaçları',
      body:
          'Veriler; finansal hesaplamaları ve kaydedilmiş senaryo özelliğini '
          'sunmak, kullanıcı tercihlerini hatırlamak, ücretsiz kullanım '
          'kotasını ve tekrar eden işlemleri yönetmek, hizmet güvenliğini '
          'sağlamak ve Sentry etkin olan buildlerde başlangıç/çalışma '
          'hatalarını teşhis etmek amacıyla '
          'işlenir. Uygulama kodunda reklam, davranışsal pazarlama veya veri '
          'satışı entegrasyonu bulunmamaktadır.',
    ),
    LegalSection(
      heading: '4. Cihazda ve Sunucuda İşleme',
      body:
          'Tema, dil, favoriler, onboarding/hukuki metin kaydı ve geçici '
          'paylaşım görselleri cihazda işlenir. Cihaz tanımlayıcısı güvenli '
          'yerel depoda tutulur. Hesaplama girdileri hizmetin API sunucusuna '
          'gönderilir. Kaydettiğiniz senaryolar API sunucusuna gönderilir ve '
          'daha sonra cihazlarınıza gösterilmek üzere sunucudan alınır. Bu '
          'nedenle senaryoların yalnız cihazda tutulduğu söylenemez. Bir '
          'sonuç kartını paylaşmayı seçtiğinizde finansal özet ve PNG, sistem '
          'paylaşım arayüzüne verilir. Seçtiğiniz mesajlaşma, sosyal medya, '
          'dosya veya fotoğraf uygulaması içeriğin ayrı alıcısı olur ve kendi '
          'gizlilik koşulları geçerlidir; göndermeden önce önizlemeyi ve '
          'alıcıyı kontrol etmelisiniz.',
    ),
    LegalSection(
      heading: '5. Hizmet Sağlayıcıları ve Aktarımlar',
      body:
          'Veriler Saydın API altyapısını çalıştıran barındırma/ağ hizmeti '
          'sağlayıcıları tarafından işlenebilir. Store release buildleri '
          'SENTRY_DSN olmadan oluşturulmaz; bu buildlerde Sentry teknik '
          'telemetri işler. Yerel/test buildlerinde DSN yoksa Sentry '
          'devre dışıdır. Apple '
          'App Store ve Google Play, uygulama dağıtımı sırasında kendi '
          'politikaları kapsamında ayrı veriler işleyebilir. Kesin alıcı '
          'grupları, işlendikleri ülkeler ve varsa yurt dışı aktarım '
          'mekanizması yayın öncesi doğrulanıp nihai metne eklenmelidir.',
    ),
    LegalSection(
      heading: '6. Saklama ve Silme',
      body:
          'Yerel tercihler, favoriler ve onboarding kayıtları uygulama '
          'deposu temizlenene kadar; cihaz tanımlayıcısı ise güvenli yerel '
          'depo silinene kadar tutulur. iOS Keychain verilerinin yalnızca '
          'uygulamayı kaldırmakla silineceği garanti edilmez. Senaryolar '
          'uygulama içinden tek tek silinebilir. Hesap silme akışı önce '
          'sunucuya silme isteği gönderir; yalnız 200 veya 204 yanıtı '
          'doğrulandıktan sonra yerel verileri temizler. Sunucu isteği '
          'doğrulanamazsa yerel '
          'veriler ve cihaz tanımlayıcısı korunur, hata gösterilir ve aynı '
          'kimlikle yeniden denenebilir. Sunucu, yedek ve Sentry için '
          'doğrulanmış saklama '
          've imha süreleri nihai politikaya eklenmeden yayın yapılmamalıdır.',
    ),
    LegalSection(
      heading: '7. Güvenlik ve Veri Minimizasyonu',
      body:
          'API bağlantıları HTTPS kullanır. Cihaz tanımlayıcısı iOS '
          'Keychain veya Android şifreli depolama arayüzüyle saklanır. '
          'Sentry yapılandırması varsayılan kişisel veri, ekran görüntüsü, '
          'session replay, otomatik oturum takibi ve performans izlemeyi kapatır; Dart hata '
          'olaylarında istek gövdelerini ve bilinen finansal veri örüntülerini '
          'filtreler. Native crash zarfları production-like RC testinde ayrıca '
          'incelenmelidir. Filtreleme ek bir korumadır, hatasız veya eksiksiz '
          'anonimleştirme garantisi değildir.',
    ),
    LegalSection(
      heading: '8. Doğrudan Kimlik Verileri ve Çocuklar',
      body:
          'Mevcut uygulama arayüzünde ad, soyad, e-posta, telefon veya kimlik '
          'numarası isteyen bir alan yoktur; hassas konum ya da kişi listesi '
          'okuma izni istemez. Bir sonuç kartını Fotoğraflar\'a kaydetmeyi '
          'seçerseniz iOS yalnızca fotoğraf kütüphanesine ekleme izni '
          'isteyebilir; bu izin mevcut fotoğrafları okuma erişimi vermez. '
          'Uygulama 13 yaşından küçük '
          'çocuklara yönelik tasarlanmamıştır.',
    ),
    LegalSection(
      heading: '9. Haklar, Değişiklikler ve İletişim',
      body:
          'Uygulama içinden kaydedilmiş senaryoları tek tek silebilir ve '
          'hesap silme akışını başlatabilirsiniz. Gizlilik soruları ve '
          'teknik destek için iletisim@saydin.app adresine yazabilirsiniz. '
          'Resmî veri sorumlusu başvuru kanalları, resmî unvan ve tebligat '
          'adresiyle birlikte yayın öncesi açıklanmalıdır. Önemli politika '
          'değişiklikleri uygulama içinde duyurulmalı ve son güncelleme '
          'tarihi değiştirilmelidir.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 8, 18);
