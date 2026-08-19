# Paylaşım kartları UI/UX review'u

**Tarih:** 19 Ağustos 2026

**Durum:** Review tamamlandı; aksiyon planı aktif, W0/W1/W4 güvenlik ve payload temelleri development branch'inde uygulanıp tam test paketinden geçti

**Kapsam:** Hesapla/Ya Alsaydım, ters hesap, Karşılaştırma, Portföy ve DCA paylaşım kartları; önizleme, PNG üretimi, native paylaşım, metin payload'ı, kurumsal kimlik, erişilebilirlik, mahremiyet, test ve dokümantasyon

## Yönetici özeti

Mevcut sistem sağlam bir teknik tabana sahip: sonuç paylaşılmadan önce önizleme açılıyor, bütün akışlar ortak bir PNG renderer kullanıyor, çıktı 1080 px genişliğe normalize ediliyor, yüksek çözünürlüklü image kaynağı dispose ediliyor ve uygulamanın oluşturduğu kaynak PNG paylaşım sonrasında siliniyor. Kâr/nötr/zarar anlamı da yalnız renge bırakılmamış. Android plugin kopyasının ayrı retention açığı ise aşağıda P0 olarak ele alınmıştır.

Buna rağmen paylaşım yüzeyi henüz birinci sınıf ürün seviyesinde değildir. Temel sorun tek tek kozmetik kusurlardan çok sistem eksikliğidir:

1. Android'de `share_plus`, finansal PNG'nin ikinci kopyasını `cacheDir/share_plus/` altında bırakıyor; eski startup/account-wipe cleanup'ı nested kopyayı kapsamıyordu. Bu, retention ve hesap silme blocker'ıdır.
2. iPad desteklenmesine rağmen `sharePositionOrigin` gönderilmiyor; kullanılan `share_plus 10.1.4` bunu iPad için zorunlu sayıyor. Bu, beş akışın ortak release blocker'ıdır.
3. Onaylı navy/teal/off-white kimlik native ikon ve splash'te güçlü biçimde uygulanmışken paylaşım kartları Material mavisi, varsayılan font ve düz `Text('saydın')` kullanıyor. Resmî sembol runtime asset olarak paketlenmiyor.
4. Beş kart, toplamda yaklaşık 1.859 satırlık ayrı implementasyonlardan oluşuyor. Ortak artboard, frame, header, metric, inflation ve footer primitive'leri yok; aynı yapı kopyalanmış.
5. Kart yüksekliği içerikle değişiyor. Tasarlanmış ve test edilmiş tek bir sosyal artboard/safe-area sözleşmesi bulunmadığı için görsel ritim ve platform kırpma davranışı öngörülemez.
6. “Önizleme” yalnız PNG'yi gösteriyor; paylaşılacak finansal caption ve sonradan eklenen promosyon CTA görünmüyor ve düzenlenemiyor.
7. `features.share` kill-switch'i yalnız DCA'da uygulanıyor; diğer dört yol flag kapalıyken paylaşmaya devam ediyor.
8. Yardımcı metinlerin önemli bölümü WCAG AA kontrastının altında; küçük ekranda sabit 540 dp kart yaklaşık yarıya küçülüyor ve text scale kart içinde 1.0'a zorlanıyor.
9. Ana sonuç ekranı ile paylaşım artifact'i arasında tarih düzeltmeleri, enflasyon veri tarihi, partial inflation ve simülasyon dili bakımından bilgi kaybı bulunuyor.
10. Yalnız Portföy için tek golden ailesi var. Reverse, Comparison ve DCA kartları; iPad native akış; hata/fallback; semantics; TR/EN uzun içerik ve outcome varyantları korunmuyor.

Sonuç olarak öneri, mevcut beş template'i tek tek “güzelleştirmek” değil; önce `SharePayload` + `ShareCardFrame` merkezli bir paylaşım tasarım sistemi kurmak, sonra beş varyantı bu sisteme taşımaktır. Böylece marka, veri doğruluğu, mahremiyet, erişilebilirlik ve export kalitesi aynı sözleşmede çözülür.

## Öncelik özeti

| Öncelik | Karar | Neden |
|---|---|---|
| P0 | Android source + plugin cache lifecycle düzeltmesi | Finansal PNG hesap silme sonrasında kalabiliyor |
| P0 | iPad share anchor düzeltmesi | Desteklenen platformda crash/hang riski |
| P1 | Gerçek runtime brand asset + resmî palette geçişi | Native kimlik ile paylaşım yüzeyi kopuk |
| P1 | Tek `SharePayload` ve `ShareCardFrame` | Beş kopya template, payload/preview drift'i |
| P1 | Sabit canonical artboard ve safe-area | Değişken oran, kırpma ve görsel ritim sorunu |
| P1 | Caption/privacy preview ve hide/edit seçenekleri | Kullanıcı final payload'ı göremiyor |
| P1 | Ortak feature policy ve in-flight cancel | Yönetim/irade tutarsızlığı |
| P1 | Kontrast, zoom, semantics ve uzun içerik | Düşük görüş ve güvenilir export kalitesi |
| P1 | Golden + native integration matrisi | En riskli yüzeylerin çoğu testsiz |
| P2 | Çoklu çıktı/fallback: paylaş, kaydet, metni kopyala | Native share başarısızlığında çıkış yok |
| P2 | Kart bazlı bilgi yoğunluğu ve copy refinement | Minimal, dikkat çekici ve güven veren sunum |

## Doküman seti

- [Kapsam, envanter ve yöntem](01-scope-inventory-method.md)
- [Kanıtlı bulgular](02-findings.md)
- [Hedef paylaşım kartı tasarım sistemi](03-target-design-system.md)
- [UX, erişilebilirlik, platform ve QA](04-ux-accessibility-platform-qa.md)
- [Uygulama yol haritası ve kabul kriterleri](05-remediation-roadmap.md)
- [Aktif uygulama ve yürütme planı](06-implementation-execution-plan.md)

## Review doğrulama özeti

- Üç bağımsız review hattı yürütüldü: kod/mimari, marka/görsel sistem, UX/erişilebilirlik/platform.
- Beş kartın kaynakları, dört sonuç menüsü, Senaryolar replay girişi, ortak sheet/renderer, l10n, config, privacy metinleri, marka master'ları ve ilgili testler çapraz izlendi.
- `flutter analyze --fatal-infos` ilgili 10 production dosyasında temiz sonuç verdi.
- Mevcut hedefli 10 test geçti: renderer dispose, What-if result/share neutral ve Portföy preview/golden testleri.
- Portföy golden'ı 540×690 olarak görsel incelendi. Ayrıca beş kart aynı veriyle Flutter render pipeline'ında geçici bir review montage'ına alındı; çıktı üretildi ve incelendikten sonra geçici harness/artifact silindi. Test prosesi görüntü üretiminden sonra tamamlanmadığı için bu probe “geçen test” sayılmadı.
- Onaylı marka asset doğrulaması `python3 -m unittest tool.tests.test_brand_assets` ile bağımsız review hattında 4/4 geçti.
- iOS simülatöründeki önceden derlenmiş uygulama sonuç ekranına ulaşmadığı için native share başarı iddiası üretilmedi. iPad davranışı release smoke testinde ayrıca doğrulanmalıdır.

## Review sınırı

Review çalışması tasarım asset'i üretmez; karar ve uygulama sözleşmesini hazırlar. Bu sözleşmenin W0/W1 mühendislik düzeltmeleri aynı dizindeki aktif yürütme planına göre başlamıştır. Özellikle horizontal wordmark, font lisansı ve disclaimer metni Brand/Product/Legal onayı gerektirir. Engineering bu girdileri tahmin ederek kalıcı marka ya da hukuki metin üretmemelidir.
