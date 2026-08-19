# Ürün, UX, erişilebilirlik ve dokümantasyon incelemesi

**Tarih:** 18 Ağustos 2026
**Kapsam:** `account`, `config`, `favorites`, `legal`, `onboarding`,
`scenarios`, `settings`; uygulama kabuğu, ortak tema/widget/l10n katmanı,
tüm sunum sayfa/widget'larına yapılan çapraz tarama (finansal hesaplama
matematiği hariç), testler, `README.md`, `docs/**`, platform metinleri ve
asset metadatası. Uygulama kodu değiştirilmedi.

## Sonuç özeti

Birinci sınıf deneyim için yayın öncesi ele alınması gereken **13 bulgu** var:
**2 P0, 5 P1, 5 P2, 1 P3**. En önemli riskler: yayınlanmaya hazır olmayan
yasal metin/izin akışı, uzaktan konfigürasyonun başlangıç yarışında yanlış
planla kullanılması, geri alınamaz senaryo silme ve erişilebilirlikte test
edilmemiş büyük boşluk.

| Öncelik | Adet | Anlam |
|---|---:|---|
| P0 | 2 | Yayın/uyumluluk engeli |
| P1 | 5 | Kullanıcı verisi, temel akış veya önemli erişilebilirlik riski |
| P2 | 5 | Belirgin kalite/geri-bildirim/dokümantasyon borcu |
| P3 | 1 | Düşük riskli iyileştirme |

## Bulgular

### P0 — Legal / yayın engeli — yasal metinler şablon olarak işaretlenmiş

**Kanıt:** `lib/features/legal/data/sources/privacy_policy_tr.dart:3-4` ve
`privacy_policy_en.dart:3-4` metinleri açıkça “yer tutucu/template” ve
yayından önce hukuk danışmanlığı gerektirir diye tanımlıyor. KVKK kaynağındaki
yorum da veri sorumlusu ve tebligat bilgilerinin tamamlanmasını istiyor
(`kvkk_disclosure_tr.dart:3-8`). Buna rağmen bu dosyalar Settings ve
onboarding'de gerçek kullanıcıya sunuluyor (`settings_page.dart:29-40`,
`onboarding_page.dart:359-367`).

İçerik doğruluğu da release öncesi doğrulanmalıdır: politika “sunucularda
kullanıcıya özel veri tutulmaz” diyor (`privacy_policy_tr.dart:46-52`,
`privacy_policy_en.dart:46-53`), ancak ürün cihaz kimliğiyle kota uygular ve
hesap silme için `/v1/account` isteği yapar
(`account_data_repository_impl.dart:90-105`). CLAUDE ayrıca `/v1/account/data-export`
akışını vaat ediyor (`CLAUDE.md:453`), fakat `rg` ile bu endpoint ya da export
özelliği için başka uygulama çağrısı bulunmadı.

**Etki ve senaryo:** Kullanıcı uygulamanın veri sorumlusunu, resmi başvuru
kanalını ve işleme/aktarım dayanağını bağlayıcı biçimde öğrenemeden uygulamayı
kullanmaya başlar. Store beyanı ve KVKK/GDPR yükümlülükleri için ürünün kendi
kaynak kodu bu metinlerin yayın onayı almadığını söylüyor. Bu, hukuki görüş
gerektiren bir yayın engelidir; ihlal hükmü değil, doğrulanması zorunlu bir
uyumluluk riski olarak işaretlenmiştir.

**Uygulanabilir düzeltme:** Hukuk/uyumluluk sahibiyle TR asıl metnini ve EN
çevirisini onaylatın; gerçek tüzel kişi unvanı, adres/tebligat ve başvuru
kanalını ekleyin; şablon yorumlarını kaldırın; doküman sürümü, onay tarihi ve
release sign-off kontrolünü yayın kontrol listesine dahil edin. Her veri
toplama, saklama, silme ve export iddiasını backend sözleşmesiyle satır satır
uzlaştırın; uygulamada olmayan export'u ya uygulayın ya metinden/CLAUDE
sözleşmesinden çıkarın.

### P0 — Marka/asset — iki platformda varsayılan Flutter launcher ikonu

**Kanıt:** iOS pazarlama ikonu asset manifestinde
`ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json:112-115`, Android
launcher ise `android/app/src/main/res/mipmap-*/ic_launcher.png` altında
tanımlı. Görsel incelemede iOS 1024px ikonu ve Android launcher PNG'si
varsayılan Flutter logosu çıktı.

**Etki ve senaryo:** Kullanıcı ana ekranda ve mağaza sayfasında Saydın yerine
varsayılan geliştirme logosu görür; finansal üründe güven ve bulunabilirlik
kaybı yaratır, store varlığı da tamamlanmamış görünür.

**Uygulanabilir düzeltme:** Marka ekibince onaylı özgün adaptive Android ikon
(foreground/background + tüm density) ve iOS AppIcon setini üretin; gerçek
cihaz/simulator ve mağaza önizlemelerinde doğrulayın. Launch screen ile ikon
renk dilini de eşleyin.

### P1 — State/plan UX — uzaktan konfigürasyon ilk yüklemede yarışa giriyor

**Kanıt:** `app.dart:60-68` tüm cubit'leri aynı anda yaratıp `AppConfigCubit`
yüklemesini başlatıyor; `AppConfigCubit` başlangıçta `defaultConfig` ile
çalışıyor (`app_config_cubit.dart:13-20`). `ScenariosPage` ilk frame'de bu
başlangıç state'inden `tier.name` alıp isteği gönderiyor
(`scenarios_page.dart:83-88`); sayfa `AppConfigCubit` değişimini dinlemiyor.
Benzer biçimde What-if, Comparison, Portfolio ve DCA feature flag/limitlerini
`read` ile alıyor (`what_if_page.dart:192-203`, `comparison_page.dart:250,306`,
`portfolio_page.dart:238`, `dca_page.dart:202,212`) ve bu değer için reaktif
abonelik kurmuyor.

**Etki ve senaryo:** Premium kullanıcının ilk senaryo isteği `free` planıyla
gider; uzaktan kapatılmış/paywall olan özellikler ilk ekranda varsayılan
“açık” durumuyla sunulabilir. Ağ hızlı olsa dahi sıra garantisi yoktur; bu
özellikle cold start'ta rastlantısal ve desteklenmesi zor bir deneyimdir.

**Uygulanabilir düzeltme:** Konfigürasyona `loading/ready/fallback` durumu
ekleyin ve plan/flag'a bağlı sayfaları `BlocBuilder`/`BlocSelector` ile
reaktif tüketin. Alternatif olarak ana kabuğu config çözülene kadar güvenli
loading durumunda tutun; fallback kullanılacaksa görünür “sınırlı çevrimdışı
mod” davranışını tasarlayın. Premium/free cold-start ve config geç gelme widget
testleri ekleyin.

### P1 — Onboarding/legal UX — Atla, görülmeyen metin için kabul kaydı yazıyor

**Kanıt:** Yasal metin/linkler sadece son sayfada ekleniyor
(`onboarding_page.dart:358-369`), fakat üstteki **Atla** düğmesi her sayfada
aynı `_completeWithLegalAcceptance` fonksiyonunu çağırıyor
(`onboarding_page.dart:237-245`). Bu fonksiyon onay sürümünü kaydediyor
(`onboarding_page.dart:80-96`). Linkler ayrıca `GestureDetector` ile
oluşturulmuş; semantik link rolü/etiketi yok (`onboarding_page.dart:480-495`).

**Etki ve senaryo:** İlk sayfada Atla'ya basan kullanıcı, aydınlatma ve
gizlilik bağlantılarını hiç görmeden “kabul etti” olarak kaydedilir. Ekran
okuyucu kullanıcısı bu linkleri güvenilir biçimde bağlantı/eylem olarak
keşfedemez. Bu hukuki geçerliliği ayrıca uzman görüşü gerektiren, fakat ürün
tasarımı açısından açık rıza/aydınlatılmış seçim standardını karşılamayan bir
akıştır.

**Uygulanabilir düzeltme:** Atla'yı ya son sayfaya yönlendirin ya da yasal
bildirimi/linkleri Atla öncesi görünür yapın. Gerekiyorsa ayrı, açık etiketli
bir checkbox/onay CTA'sı kullanın; linkleri `Link`/`InkWell` + `Semantics(link:
true, label: …)` ile klavye/ekran okuyucu erişimine açın. Kabul kaydına zaman,
locale ve belge sürümünü ekleyin; yazma başarısızsa kullanıcının onaysız devam
ettiğini sessizce kaydetmeyin.

### P1 — Legal state — yeni belge sürümü hiç zorunlu olarak gösterilmiyor

**Kanıt:** `OnboardingRepository.getAcceptedLegalVersion` tanımlı ve saklanmış
değeri döndürüyor (`onboarding_repository.dart:14-16`,
`onboarding_repository_impl.dart:38-40`); çağrı yeri yok. Aynı interface,
metin sürümü değişince kullanıcıya tekrar gösterilmesinin “ileride implement
edilecek” olduğunu kabul ediyor (`onboarding_repository.dart:9-11`).

**Etki ve senaryo:** Politika v2'ye yükseltilse bile v1 kabulü olan kullanıcı
uygulamayı doğrudan açar; yeni bildirim/onay akışı çalışmaz. Kullanıcı fark
etmeden güncellenmiş veri koşulları altında devam eder.

**Uygulanabilir düzeltme:** Başlangıçta kabul edilen sürümü `current` ile
karşılaştırın; eski/null ise güncel legal akışını gösterin. Uygulanacak hukuki
temele göre “bilgilendirildi” ile “rıza verdi” kayıtlarını ayırın ve bu geçişe
birim/widget testleri ekleyin.

### P1 — Senaryo silme / erişilebilirlik — geri dönüş veya klavye eşdeğeri yok

**Kanıt:** Kart yalnızca sağdan sola `Dismissible` ile siliniyor
(`scenarios_page.dart:41-44`); `confirmDismiss`, `SnackBarAction` veya görünür
silme düğmesi bulunmuyor. Dismiss sonrası snackbar yalnız “silindi” mesajını
gösteriyor (`scenarios_page.dart:90-100`); backend hatası sonradan listeyi
geri yüklüyor (`scenarios_bloc.dart:141-164`). Kapsam genelinde açık
`Semantics`, `semanticLabel` ve `Tooltip` hit'i **0**.

**Etki ve senaryo:** Dokunmatik kullanıcı yanlış swipe ile kayıtlı finansal
senaryoyu kalıcı olarak silebilir. TalkBack/VoiceOver, fiziksel klavye ve switch
access kullanıcısının bu işlevi başlatabileceği eşdeğer bir kontrol yoktur.
Sunucu gecikirse kullanıcı önce “silindi”, sonra hata snackbar'ı görür; güven
kaybı ve durum belirsizliği oluşur.

**Uygulanabilir düzeltme:** Silme öncesi erişilebilir onay diyaloğu veya süreli
Undo ekleyin; callback ile restore endpoint/yerel state'i bağlayın. Kartın
overflow menüsüne etiketli Sil eylemi koyun, `Dismissible` için semantik
hint/announce sağlayın ve onay, undo, başarısız rollback'i widget testleriyle
doğrulayın.

### P1 — Responsive / text scaling — onboarding ve hesap silme dar/yüksek metinde taşabilir

**Kanıt:** Onboarding, kaydırılamayan bir `Column` içinde iki sabit `Expanded`
alan, 56px CTA ve son sayfada ek legal metin kullanıyor
(`onboarding_page.dart:220-435`); alt içerik `Text.rich` ile ekleniyor
(`onboarding_page.dart:503-515`). Delete-account sayfası da `SafeArea` altında
scroll olmayan `Column` kullanıyor (`delete_account_page.dart:72-126`).

**Etki ve senaryo:** Büyük erişilebilirlik yazı boyutu, küçük ekran, yatay
mod veya klavye açıkken legal metin/CTA ya da silme onay butonu görünür alanın
dışına taşabilir; kullanıcı akışı tamamlayamaz. Bu davranış çalıştırılmış
widget/golden testle doğrulanmamıştır.

**Uygulanabilir düzeltme:** Bu ekranları `SingleChildScrollView`/uyarlanabilir
layout ile kurun; CTA'yı keyboard inset'e göre görünür tutun. 200% text scale,
320dp genişlik, yatay orientation ve klavye açık testlerini ekleyin; hareketli
onboarding efektlerini `MediaQuery.disableAnimations`/reduced motion tercihiyle
azaltın.

### P2 — Senaryo yenileme — pull-to-refresh tamamlanmayı beklemiyor

**Kanıt:** `RefreshIndicator.onRefresh` `async` olsa da sadece event dispatch
edip hemen döner (`scenarios_page.dart:159-163`). `ScenariosRequested`
sonucunu temsil eden `Future` bu callback'e bağlanmamış.

**Etki ve senaryo:** Kullanıcı aşağı çektiğinde spinner ağ isteği sürerken
anında kapanır; liste güncellenmeden “yenilendi” algısı oluşur.

**Uygulanabilir düzeltme:** Bloc'a tamamlanabilir bir refresh API'si verin veya
`Completer`/state dinleyicisiyle `ScenariosLoaded/Failure` gelene kadar future'ı
bekletin. Başarı ve hata durumları için widget test ekleyin.

### P2 — Tema ve kontrast — birden çok yüzey sabit açık renk kullanıyor

**Kanıt:** Tema itself sabit `Colors.white` ve `Colors.grey.shade900` tabanlı
bottom-navigation arka planı kullanıyor (`app_theme.dart:16-35`). Skeleton
kutuları beyaz (`skeleton_card.dart:68-77`), paylaşım sheet handle'ı sabit gri
(`share_preview_sheet.dart:68-75`) ve senaryo tip chip/avatar'ları açık
orange/blue/purple/teal `shade50` ile sabit (`scenario_card.dart:190-200`,
`273-280`, `388-395`, `501-515`). Hata snackbar'ı da sabit kırmızı
(`scenarios_page.dart:116-123`).

**Etki ve senaryo:** Dark mode'da bu yüzeyler uygulamanın tema hiyerarşisini
kırar, yüksek parlaklıklı yamalar üretir; bazı küçük `shade700` metin/ikonların
kontrastı cihaz/tema kombinasyonunda yeterli olmayabilir. Finansal sonuç
ürününde uzun süreli kullanım konforu düşer.

**Uygulanabilir düzeltme:** `ColorScheme` semantic rollerini (`surfaceContainer`,
`secondaryContainer`, `on…Container`, `errorContainer`) ve tema extension'ını
kullanın; açık/koyu kontrastını WCAG AA ile ölçün. Light/dark widget/golden
testlerinde chips, skeleton, snackbar ve bottom navı kapsayın.

### P2 — Erişilebilirlik güvence ağı — sunum katmanında explicit semantics yok, widget testleri çok sınırlı

**Kanıt:** `lib/**` taramasında `Semantics(`, `semanticLabel:` ve `Tooltip(`
için **0** hit bulundu. 9 page dosyası ve 20 stateful widget'a karşılık
testlerde yalnız **5** `testWidgets` hit'i var; bu kapsamda account/config/
favorites/legal/onboarding/scenarios/settings için page widget testi **0**.
Mevcut test envanteri cubit/repository/bloc ağırlıklı (`test/features/...`).

**Etki ve senaryo:** Temel Flutter kontrolleri bazı varsayılan semantikler
sağlasa da custom gesture, grafik, ikon-only eylem, yükleme ve hata dönüşleri
ekran okuyucu/klavye açısından bilinçli biçimde doğrulanmıyor. Regresyonlar CI
yeşilken kullanıcıya ulaşabilir.

**Uygulanabilir düzeltme:** Her sayfaya semantic tree, focus order, minimum
48dp hedef, keyboard activation, loading/error/empty ve 200% scale testleri
ekleyin. Custom kontrollerde anlamlı label/hint verin; dekoratif ikonları
exclude edin. `SettingsIconButton` gibi ikon-only eylemlere tooltip/semantic
label ekleyin (`settings_icon_button.dart:12-24`).

### P2 — Dokümantasyon ve otomatik review kapsamı birbiriyle çelişiyor

**Kanıt:** README Flutter 3.41.0 diyor (`README.md:3`), kanonik pin 3.41.4
(`pubspec.yaml:10-14`, `CLAUDE.md:7`). README yalnız iki komut veriyor
(`README.md:5-14`); gerekli `API_BASE_URL`, test ve l10n akışını söylemiyor.
Bu doğrudan çalıştırma hatasıdır: `ApiClient` boş `API_BASE_URL` için fail-loud
validation yapıyor (`injection.dart:70-81`), yani README'deki düz `flutter run`
uygulamayı başlatamaz. Geliştirme kılavuzu bu repo kökündeyken
`cd src/Saydin.Client` öneriyor
(`development-guide.md:23-28`) ve hook'un çalıştırdığı test adımını atlıyor
(`development-guide.md:36-40` karşılığı `.githooks/pre-commit:41-56`).
`pubspec.yaml:4` conventional-commit version override derken CLAUDE tag-driven
modeli tanımlıyor (`CLAUDE.md:239-295`). CLAUDE Mermaid zorunlu/ASCII yasak
diyor (`CLAUDE.md:540-548`), mimari dosyası ASCII ağaç ve state diyagramları
barındırıyor (`architecture.md:7-62`, `97+`). Son olarak CodeRabbit
konfigürasyonu `master` base'ini yazıyor ve docs'u hariç tutuyor
(`.coderabbit.yaml:12-21`); repo CI hedefleri ise `main`/`development`
(`.github/workflows/ci.yml:13-18`). Bununla birlikte PR #37'de CodeRabbit
yorumları mevcut olduğundan `base_branches` alanının uygulanmadığı, şemasının
eskidiği veya review'un başka yolla tetiklendiği anlaşılıyor; gerçek davranış
ile dosyada beyan edilen niyet tutarlı değil. Aynı config clean architecture
yönünü de yanlış `presentation → domain → data` yazıyor
(`.coderabbit.yaml:30`; doğrusu `presentation → domain ← data`).

**Etki ve senaryo:** Yeni geliştirici yanlış SDK/klasör/release modeliyle
başlar; otomatik review kapsamı dosyadaki ayarla güvenilir biçimde tahmin
edilemez ve docs değişiklikleri açıkça kapsam dışıdır. Mimari kuralın yanlış
anlatılması bağımlılık ihlallerini normalleştirir.

**Uygulanabilir düzeltme:** Tek kaynakları belirleyip README'yi hızlı başlangıç
ve önkoşul/define/test bağlantılarıyla güncelleyin; doküman kurallarını kod/CI
ile eşleyin. CodeRabbit base branch'lerini `main` ve `development` yapın,
docs için en az doğruluk/l10n link kontrolü ekleyin ve dependency yönünü
düzeltin.

### P2 — Hesap silme — backend silinmese de yerel wipe ve onboarding reseti yapılıyor

**Kanıt:** Cubit backend sonucunu `backendOk` olarak alsa da her durumda
`wipeLocalData()` çağırıyor (`account_deletion_cubit.dart:39-81`). Repository
bu davranışı “yerel silme her zaman önceliklidir” diye tanımlıyor
(`account_data_repository.dart:20-27`). Buna karşılık proje kuralı backend 200
olmadan local cleanup olmamasını söylüyor (`CLAUDE.md:451-455`).

**Etki ve senaryo:** Ağ kesintisinde kullanıcı “hesabımı sil” der; cihazdaki
kanıtlar/senaryolar yok edilir, uzaktaki kayıt ve kullanım kotası kalabilir.
UI bunu partial success olarak bildirse de kullanıcı sonradan talebi tekrar
gönderecek kimlik/akış bilgisine sahip değildir. Hangi modelin uygun olduğu
hukuki/ürün kararı gerektirir; mevcut belgeler çelişiyor.

**Uygulanabilir düzeltme:** Önce ürün ve hukuk sahibiyle sözleşmeyi seçin.
Remote silme zorunluysa local wipe'ı 2xx sonrasına taşıyın ve retryable pending
request saklayın. Local-first silme seçilecekse doğrulama metnini, onay ekranını
ve support/retry yolunu açıkça güncelleyin; partial wipe hatasında hangi
verilerin silindiğini kullanıcıya dürüstçe bildirin.

### P3 — Küçük geri bildirim boşluğu — ayar/favori kalıcılık hatası yalnız telemetride

**Kanıt:** Settings kaydetme hatasında state değişmeden yalnız ErrorReporter'a
gider (`settings_cubit.dart:40-48`, `54-63`). Favorite toggle rollback yapar
ama kullanıcı mesajı vermez (`favorites_cubit.dart:43-54`).

**Etki ve senaryo:** Kullanıcı tema/dil veya favori seçiminin neden eski haline
döndüğünü anlayamaz; çevrimdışı/depo hatası uygulamanın keyfi davranışı gibi
görünür.

**Uygulanabilir düzeltme:** Tekrarsız, lokalize snackbar/banner ile “ayar
kaydedilemedi, tekrar deneyin” geri bildirimi verin; optimistic rollback için
aria/semantics announcement da ekleyin.

## Doğrulanmış temiz kontroller

- TR ve EN ARB'lerinde kullanıcı-facing key sayısı eşit: **238 / 238**.
  Key ve benzersiz placeholder kümeleri arasında fark yok; ARB şema kontrolü
  geçti.
- L10n'de bulunan sayım/ICU çoğulları kaynaklarda iki dilde de yer alıyor;
  mevcut `test/l10n/app_localizations_plural_test.dart` bu alan için olumlu
  bir güvence sağlıyor.
- Kullanıcıya görünen standart uygulama metinlerinde (legal metinler ve
  paylaşım kartı tasarım metinleri hariç) doğrudan hard-coded string taraması
  yalnız senaryo kartındaki dekoratif madalya işaretini buldu
  (`scenario_card.dart:429`).
- Legal dokümanlar cihaz içi kaynak olduğundan offline okunabiliyor
  (`legal_repository_impl.dart:12-24`); görüntüleyici scrollable ve metin
  seçilebilir (`legal_document_page.dart:20-42`, `59-69`).
- Hesap silme yazılı onay sözcüğü ve Türkçe büyük/küçük harf eşlemesi doğru
  niyetle uygulanmış (`delete_account_page.dart:85-110`).
- Senaryo state listeleri immutable, silme rollback'i uygulanmış
  (`scenarios_state.dart:21-87`, `scenarios_bloc.dart:141-164`).
- iOS izin açıklaması TR/EN lokalize ve add-only photo library izniyle sınırlı
  (`ios/Runner/Info.plist:81-94`, `ios/Runner/{tr,en}.lproj/InfoPlist.strings:1`).

## Test/araç notu ve inceleme envanteri

- İncelenen hedef envanteri: ilgili feature/core/l10n/docs/test ağaçlarında
  **108 dosya**. Yüksek riskli tüm sunum akışları satır bazında incelendi;
  geri kalan hedeflerde hard-coded metin/renk, state, loading/error, semantics
  ve test otomatik taramaları uygulandı.
- Çalıştırılması denenen `flutter analyze --fatal-infos` ve kapsamlı feature
  test komutu **çalıştırılamadı**: değerlendirme ortamında `flutter` ve `dart`
  PATH'te yoktu. Bu bir proje testi başarısızlığı değildir; CI veya Flutter
  3.41.4 kurulu bir yerel ortamda tekrar çalıştırılmalıdır.
- İnceleme kod değişikliği yapmadı. Bu rapor tek yeni dokümantasyon çıktısıdır.

## Önerilen uygulama sırası

1. P0 legal sign-off ve özgün uygulama ikonları.
2. Config-ready başlangıç sözleşmesi; premium/free cold-start testleri.
3. Onboarding legal görünürlük/sürüm kontrolü ve senaryo silmede erişilebilir
   confirm/undo.
4. Text scale/dark-mode/semantics widget test paketi ve responsive düzeltmeler.
5. Doküman/CodeRabbit tek-kaynak uyumu ile kalıcı kalite kapısı.
