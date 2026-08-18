import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// KVKK Madde 10 teknik envanteriyle eşleştirilmiş yayın taslağı.
///
/// Veri sorumlusunun kimliği/adresi, kategori bazında KVKK Madde 5 işleme
/// şartı, kesin alıcı/ülke ve Madde 9 aktarım mekanizması, saklama-imha takvimi
/// ile resmî başvuru kanalları `docs/legal/legal-release-signoff.md` içinde
/// tamamlanıp hukuk/DPO tarafından onaylanmadan bu taslak yayınlanmamalıdır.
final LegalDocument kvkkDisclosureTr = LegalDocument(
  type: LegalDocumentType.kvkkDisclosure,
  title: 'KVKK Aydınlatma Metni — Yayın Taslağı',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Taslak Durumu ve Veri Sorumlusu',
      body:
          'Bu metin, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) '
          'Madde 10 için hazırlanmış teknik envanter taslağıdır; yayın için '
          'onaylanmış aydınlatma metni değildir. Veri sorumlusunun resmî '
          'ticaret unvanı, tebligat adresi ve varsa temsilcisi henüz bu '
          'repoda doğrulanmamıştır. Bu bilgiler tamamlanmadan uygulama '
          'yayınlanmamalıdır. Teknik/gizlilik soruları için mevcut iletişim '
          'adresi: iletisim@saydin.app.',
    ),
    LegalSection(
      heading: '2. İşlenen Kişisel Veri Kategorileri',
      body:
          '• Her API isteğine eklenen kalıcı, takma adlı (psödonim) cihaz '
          'tanımlayıcısı. Kota ve tekrar tespiti için kullanılan bu UUID '
          'anonim veri değildir.\n'
          '• İşletim sistemi, azaltılmış işletim sistemi sürümü, uygulama '
          'sürümü ve seçili/sistem dili gibi teknik veriler.\n'
          '• Finansal hesaplama girdileri: varlık sembolü/adı, tutar ve türü, '
          'tarihler, dönem, enflasyon seçimi, karşılaştırma ve portföy '
          'bileşenleri.\n'
          '• Kaydedilmiş senaryo verileri: hesaplama girdileri, senaryo türü, '
          'sunucu kimliği, oluşturulma zamanı ve türe özgü ek alanlar.\n'
          '• Cihazda saklanan tema, dil, favoriler ve onboarding durumu; '
          'gösterilen hukuki metin bundle sürümü/hash’i, belge kimlikleri, '
          'gösterim dili ve UTC zamanı ile bildirimin yalnız görüldüğünü veya '
          'isteğe bağlı işaretlendiğini belirten kayıt.\n'
          '• Kullanıcı paylaşmayı seçerse sistem paylaşım arayüzüne verilen '
          'finansal sonuç özeti ve PNG; kullanıcının seçtiği hedef uygulama '
          'bu içeriğin ayrı alıcısıdır.\n'
          '• Store release buildlerinde Sentry hata/çökme telemetrisi '
          'etkindir; DSN verilmeyen yerel/test buildlerinde kapalıdır. SDK '
          'uygulama arayüzü ve hukuki bildirimden önce başlatıldığından '
          'başlangıç ile bildirim gösterim/kayıt hataları da işlenebilir. '
          'Teknik eylem izleri ve uygulama/işletim sistemi sürümü işlenebilir. '
          'Ekran görüntüsü, session replay, otomatik oturum takibi ve performans izleme '
          'kapalıdır. Dart hata olayları filtrelenir; bu filtreleme native '
          'crash zarfı için doğrulanmış garanti veya mutlak anonimleştirme '
          'garantisi değildir.\n\n'
          'Mevcut arayüz ad, soyad, e-posta, telefon veya kimlik numarası '
          'istemez; hassas konum ya da kişi listesi okuma izni yoktur. '
          'Kullanıcı sonuç kartını Fotoğraflar\'a kaydetmeyi seçerse iOS '
          'yalnızca fotoğraf kütüphanesine ekleme izni isteyebilir; bu izin '
          'mevcut fotoğrafları okuma erişimi vermez.',
    ),
    LegalSection(
      heading: '3. İşleme Amaçları',
      body:
          'Veriler; finansal hesaplama ve kaydedilmiş senaryo hizmetlerini '
          'sunmak, kullanıcı tercihlerini hatırlamak, ücretsiz kullanım '
          'kotasını ve tekrar eden işlemleri yönetmek, hizmet güvenliğini '
          'sağlamak ve Sentry etkin olan buildlerde başlangıç/çalışma '
          'hatalarını teşhis etmek '
          'amaçlarıyla işlenir. Mevcut istemci kodunda reklam, '
          'davranışsal pazarlama veya veri satışı entegrasyonu yoktur.',
    ),
    LegalSection(
      heading: '4. Toplama Yöntemi ve Hukuki Sebep',
      body:
          'Cihaz/uygulama teknik verileri API istekleri sırasında otomatik '
          'olarak; hesaplama ve senaryo verileri kullanıcının uygulamadaki '
          'seçimleriyle elektronik ortamda; yerel tercihler cihaz depolama '
          'arayüzleriyle; telemetri ise store release buildlerinde ve Sentry '
          'yapılandırılmış diğer buildlerde SDK aracılığıyla elde edilir. Her '
          'veri kategorisi için uygulanacak '
          'KVKK Madde 5 işleme şartı hukuk/DPO tarafından belirlenip açıkça '
          'yazılmamıştır. Bu belirleme tamamlanmadan metin nihai değildir; '
          'aydınlatma metni tek başına açık rıza yerine geçmez.',
    ),
    LegalSection(
      heading: '5. Alıcı Grupları ve Aktarım',
      body:
          'API verileri Saydın hizmet altyapısını işleten barındırma ve ağ '
          'hizmeti sağlayıcıları tarafından işlenebilir. Store release '
          'buildleri SENTRY_DSN olmadan oluşturulmaz ve Sentry bu buildlerde '
          'teknik telemetri işler; DSN olmayan yerel/test buildlerinde '
          'devre dışıdır. Apple '
          'App Store ve Google Play uygulama dağıtımı sırasında kendi '
          'politikaları kapsamında ayrı veri işleyebilir. Kullanıcının '
          'sistem paylaşım arayüzünde seçtiği mesajlaşma, sosyal medya, dosya '
          'veya fotoğraf uygulaması paylaşılan içeriği kendi koşullarıyla '
          'işler. Kesin alıcı '
          'grupları, sağlayıcıların işleme ülkeleri ve varsa KVKK Madde 9 '
          'uyarınca yurt dışı aktarım mekanizması doğrulanıp yayın öncesi '
          'nihai metne eklenmelidir.',
    ),
    LegalSection(
      heading: '6. Saklama, Güvenlik ve Silme',
      body:
          'Tema, dil, favoriler ve onboarding kayıtları uygulama deposu '
          'temizlenene kadar; cihaz tanımlayıcısı güvenli yerel depo '
          'silinene kadar tutulur. iOS Keychain verilerinin yalnızca '
          'uygulamayı kaldırmakla silineceği garanti edilmez. Hesaplama '
          'girdileri API sunucusuna gönderilir; kaydedilmiş senaryolar '
          'sunucuda saklanır ve uygulamadan tek tek silinebilir. Hesap silme '
          'akışı sunucuya istek gönderir; yalnız 200 veya 204 yanıtından sonra yerel '
          'verileri temizler. Sunucu sonucu doğrulanamazsa yerel veri ve '
          'cihaz tanımlayıcısı korunur, hata gösterilir ve aynı kimlikle '
          'yeniden denenebilir. API HTTPS kullanır '
          've cihaz tanımlayıcısı güvenli yerel depodadır. Sunucu, yedek ve '
          'Sentry için kesin saklama/imha süreleri doğrulanmadan bu metin '
          'nihai değildir.',
    ),
    LegalSection(
      heading: '7. KVKK Madde 11 Kapsamındaki Haklar',
      body:
          'KVKK Madde 11 uyarınca kişisel verilerinizin işlenip işlenmediğini '
          'öğrenme; işlenmişse bilgi talep etme; işleme amacını ve amaca '
          'uygun kullanılıp kullanılmadığını öğrenme; yurt içinde veya yurt '
          'dışında aktarıldığı üçüncü kişileri bilme; eksik veya yanlış '
          'işlenmişse düzeltilmesini isteme; şartları oluştuğunda silme veya '
          'yok etme ve bu işlemlerin aktarılan üçüncü kişilere bildirilmesini '
          'isteme; münhasıran otomatik sistemlerle analiz sonucu aleyhinize '
          'bir sonucun ortaya çıkmasına itiraz etme ve kanuna aykırı işleme '
          'nedeniyle zarara uğramanız hâlinde giderim talep etme haklarına '
          'sahipsiniz.',
    ),
    LegalSection(
      heading: '8. Başvuru Kanalları',
      body:
          'Uygulama içinden senaryoları silebilir ve hesap silme akışını '
          'başlatabilirsiniz. iletisim@saydin.app adresi gizlilik soruları '
          've teknik destek içindir; tek başına bütün resmî KVKK '
          'başvurularının geçerli kanalı olduğu ileri sürülmemektedir. Veri '
          'sorumlusunun yazılı başvuru adresi, KEP adresi varsa KEP kanalı ve '
          'diğer geçerli başvuru yöntemleri resmî unvanla birlikte yayın '
          'öncesi açıklanmalıdır. Geçerli başvurular, talebin niteliğine göre '
          'en kısa sürede ve en geç 30 gün içinde sonuçlandırılır.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 8, 18);
