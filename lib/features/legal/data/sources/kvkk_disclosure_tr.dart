import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// KVKK 6698 sayılı kanun Madde 10 kapsamında aydınlatma metni — Türkçe.
///
/// Bu metin "veri sorumlusu" tarafından doldurulacak ŞABLONDUR. Yayına almadan
/// önce hukuki danışmanlık alın ve aşağıdaki yer tutucuları kendi şirket
/// bilgilerinizle değiştirin: [VERİ_SORUMLUSU], [İLETİŞİM_ADRESİ],
/// [BAKAN_ÜYE], [KEP_ADRESİ].
///
/// `final` (const değil) çünkü `DateTime.utc` const değil. Tek seferlik
/// modul yükleme maliyeti var, runtime'da değişmez.
final LegalDocument kvkkDisclosureTr = LegalDocument(
  type: LegalDocumentType.kvkkDisclosure,
  title: 'KVKK Aydınlatma Metni',
  // Metin güncellendiğinde bu tarih de güncellenmeli.
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Veri Sorumlusu',
      body:
          '6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") kapsamında '
          'kişisel verileriniz Saydın ("Veri Sorumlusu") tarafından, aşağıda '
          'açıklanan amaçlarla ve mevzuatın izin verdiği sınırlar dahilinde '
          'işlenmektedir.\n\n'
          'İletişim: iletisim@saydin.app',
    ),
    LegalSection(
      heading: '2. İşlenen Kişisel Veriler',
      body:
          'Saydın uygulamasını kullanırken aşağıdaki veriler işlenir:\n\n'
          '• Cihaz tanımlayıcısı (anonim UUID — sadece kullanım kotası ve '
          'tekrar tespiti için)\n'
          '• Cihaz teknik bilgileri (işletim sistemi versiyonu, uygulama '
          'versiyonu, dil tercihi)\n'
          '• Uygulama içi tercihler (tema, dil)\n'
          '• Yerel olarak saklanan senaryolar (kaydettiğiniz hesaplamalar)\n'
          '• Hata raporları (Sentry üzerinden — kişisel veri sansürlenir)\n\n'
          'Ad, soyad, e-posta, telefon, kimlik numarası gibi doğrudan '
          'kimlik bilgileriniz toplanmaz.',
    ),
    LegalSection(
      heading: '3. İşleme Amaçları',
      body:
          'Kişisel verileriniz aşağıdaki amaçlarla işlenir:\n\n'
          '• Uygulama hizmetlerinin sağlanması ve sürdürülmesi\n'
          '• Kullanıcı tercihlerinin saklanması\n'
          '• Ücretsiz plan kullanım kotasının takibi\n'
          '• Hata tespit ve giderme (debugging)\n'
          '• Yasal yükümlülüklerin yerine getirilmesi',
    ),
    LegalSection(
      heading: '4. Veri Aktarımı',
      body:
          'Kişisel verileriniz aşağıdaki üçüncü taraflarla paylaşılır:\n\n'
          '• Sentry (hata izleme — ABD merkezli, kişisel veri sansürlenmiş '
          'olarak gönderilir)\n'
          '• Apple/Google (uygulama dağıtımı ve push notification altyapısı)\n\n'
          'Yurtdışına aktarım KVKK Madde 9 kapsamında, açık rıza veya '
          'mevzuatın izin verdiği hallerde yapılır.',
    ),
    LegalSection(
      heading: '5. Saklama Süresi',
      body:
          'Yerel verileriniz (tercihler, senaryolar) yalnızca cihazınızda '
          'tutulur ve uygulamayı kaldırdığınızda silinir. Hesap silme '
          'akışını kullandığınızda tüm yerel verileriniz anında silinir. '
          'Hata raporları Sentry tarafından 90 gün saklanır.',
    ),
    LegalSection(
      heading: '6. KVKK Madde 11 Hakları',
      body:
          'KVKK Madde 11 uyarınca aşağıdaki haklara sahipsiniz:\n\n'
          '• Kişisel verilerinizin işlenip işlenmediğini öğrenme\n'
          '• İşlenmişse bilgi talep etme\n'
          '• İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını '
          'öğrenme\n'
          '• Yurtiçinde/yurtdışında aktarıldığı tarafları bilme\n'
          '• Eksik veya yanlış işlenmişse düzeltilmesini isteme\n'
          '• Silinmesini veya yok edilmesini isteme\n'
          '• Otomatik sistemlerle yapılan analiz sonucu aleyhinize bir '
          'sonuç çıkmasına itiraz etme\n'
          '• Hukuka aykırı işleme sebebiyle zarara uğramışsanız zararın '
          'giderilmesini talep etme\n\n'
          'Haklarınızı kullanmak için iletisim@saydin.app adresine '
          'başvurabilir veya uygulama içinden "Hesabımı Sil" akışını '
          'kullanabilirsiniz.',
    ),
    LegalSection(
      heading: '7. Başvuru ve İletişim',
      body:
          'KVKK Madde 13 uyarınca taleplerinizi yazılı olarak '
          'iletisim@saydin.app adresinden iletebilirsiniz. Başvurularınız '
          'en geç 30 gün içinde sonuçlandırılır.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 5, 27);
