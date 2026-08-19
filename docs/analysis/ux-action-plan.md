# Saydın UI/UX aksiyon planı

**Oluşturma tarihi:** 19 Ağustos 2026
**Kod tabanı:** `1d17be3f15ac43bd517b42054678924faaeb9222`
**Kaynaklar:** `docs/analysis/ui-ux-claude/` ve `docs/analysis/ui-ux-gpt/` altındaki bütün raporlar
**Durum:** İlk P1 uygulama dilimi tamamlandı; P0/P1 yayın kapıları kısmen açık
**İlke:** Ham bulgu sayısı iş sayısı değildir. Hiçbir kaynak bulgu silinmez; aynı kök nedene bağlı kayıtlar tek programa bağlanır ve kendi kabul maddesini korur.

## 1. Yönetici kararı

Mevcut sürüm production yayınına hazır değildir. Etkin öncelik sırası şöyledir:

1. **P0 — hukuk ve finansal sorumluluk metni:** Kullanıcıya açılan dört legal kaynak yayın taslağıdır. Ayrıca “yatırım tavsiyesi değildir / geçmiş performans garanti değildir” sözleşmesi ve Kullanım Koşulları yüzeyi yoktur. Onaylı içerik gelmeden bu kapı mühendislik tarafından tek başına kapatılamaz.
2. **P1 — güvenilir çekirdek deneyim:** başlangıç ve katalog hatalarında çıkmazlar, finansal anlam/veri invariant'ları, share doğruluğu, kullanıcı onaysız replay, kritik erişilebilirlik, native marka kimliği ve çalıştırılabilir release kanıtı kapanmalıdır.
3. **P2 — sistem kalitesi:** async sıralama, geri alınabilir eylemler, schema/ölçek dayanıklılığı, adaptif düzen, form sözleşmesi, tema/l10n ve bilgi mimarisi ortak bileşenlere taşınmalıdır.
4. **P3/fırsat — farklılaştırma:** açıklanabilir hesaplama, daha güçlü karşılaştırma/DCA/portföy içgörüleri, retention ve paylaşım döngüsü güven kapılarından sonra ele alınmalıdır.

İlk uygulama paketi olarak, sağlanan ve QA'den geçmiş “01 / Zaman İzi” kurumsal varlıklarıyla **T07 native ürün kimliği** uygulanmış; **T03 finansal temsil** programında neutral sonuç ve Comparison response invariant'ları kapatılmıştır. Legal metinler, finansal disclaimer ve policy kararları ürün/legal sahibinin onayını bekler; taslak metinler “temizlenerek” veya varsayım yoluyla finalleştirilmeyecektir.

## 2. Kapsam ve eksiksizlik kaydı

Claude setindeki 19 ana raporda **566** kayıt vardır: 16 P0, 105 P1, 213 P2, 120 P3 ve 100 fırsat; kalan 12 kayıt raporların `FIRSAT-01` gibi lot öneksiz ama yine kapsama alınan başlıklarıdır. GPT seti bunlardan bağımsız olarak 52 ana bulgu, 9 doğrulama/kör nokta ve 3 fırsatı, yani **64/64** source ID'yi doğrulama defterinde korur.

Bu plan iki düzeyi birlikte tutar:

- **Kaynak düzeyi:** A1–A8, B1–B8 ve C1–C3 raporlarındaki her başlık aşağıdaki kapsam defterinde sayılır ve en az bir programa atanır.
- **Uygulama düzeyi:** tekrarlar T01–T19 kök programlarında birleştirilir. Bir kaydın birleşmesi, reddedilmesi veya runtime kanıtı beklemesi onu kapsamdan çıkarmaz.
- **Önem düzeyi:** bağımsız verifier kararı ham etiketten üstündür. Örneğin A7-P0-01 etkin P2, B5-P0-01 etkin P1, B1-P0-01 etkin P1 ve UXC-F05 geçersizdir.

### 2.1 Kaynak rapor kapsam defteri

Aralıklar kapsayıcıdır. Bir satırdaki program listesi o rapordaki tüm P0/P1/P2/P3/fırsat kayıtlarının hedef havuzudur; program içindeki alt kabul maddeleri kaydın özgün etkisini korur.

| Kaynak | P0 | P1 | P2 | P3 | Fırsat | Toplam | Atandığı programlar |
|---|---:|---:|---:|---:|---:|---:|---|
| A1 Onboarding/legal/bootstrap | 01–02 | 01–06 | 01–13 | 01–09 | 01–06 | 36 | T01, T02, T06, T07, T12, T13, T14, T15, T19 |
| A2 What-if | — | 01–09 | 01–19 | 01–06 | 01–06 | 40 | T02, T03, T04, T05, T06, T12, T14, T16, T19 |
| A3 DCA | — | 01–06 | 01–11 | 01–08 | 01–05 | 30 | T02, T03, T04, T06, T12, T14, T16, T19 |
| A4 Portfolio | 01–02 | 01–07 | 01–12 | 01–09 | 01–07 | 37 | T02, T03, T04, T06, T09, T10, T11, T12, T13, T16, T19 |
| A5 Comparison | — | 01–02 | 01–06 | 01–03 | 01–04 | 15 | T02, T03, T04, T06, T12, T19 |
| A6 Scenarios/favorites | 01–03 | 01–06 | 01–14 | 01–10 | 01–05 | 38 | T02, T05, T06, T09, T10, T11, T12, T13, T14, T15, T19 |
| A7 Settings/account deletion | 01 | 01–08 | 01–12 | 01–06 | 01–05 | 32 | T01, T06, T09, T10, T13, T14, T15, T17, T19 |
| A8 Share-card system | — | 01–02 | 01–06 | 01–02 | 01–03 | 13 | T04, T05, T06, T07, T08, T12, T13, T19 |
| B1 Accessibility | 01 | 01–09 | 01–17 | 01–08 | 01–06 | 41 | T06, T08, T12, T13, T16 |
| B2 Design system/theme | — | 01–05 | 01–14 | 01–07 | 01–06 | 32 | T06, T07, T08, T12, T13, T19 |
| B3 L10n/microcopy | 01 | 01–07 | 01–15 | 01–14 | 01–07 | 44 | T01, T03, T04, T05, T06, T14, T16, T17, T18 |
| B4 State/feedback/error | 01–02 | 01–08 | 01–18 | 01–06 | 01–07 | 41 | T02, T03, T05, T08, T09, T10, T11, T12, T13, T17 |
| B5 IA/navigation | 01 | 01–05 | 01–09 | 01–05 | 01–07 | 27 | T05, T07, T10, T12, T15, T17, T19 |
| B6 Forms/input/validation | — | 01–09 | 01–11 | 01–08 | 01–08 | 36 | T02, T03, T06, T09, T12, T14, T16 |
| B7 Motion/performance | — | — | 01–06 | 01–04 | 01–03 | 13 | T08, T09, T12, T13 |
| B8 Platform/adaptability | 01 | 01–03 | 01–12 | 01–06 | 01–06 | 28 | T07, T08, T12, T15, T17 |
| C1 Documentation/process | — | 01–02 | 01–06 | 01–02 | 01–03 | 13 | T08, T13, T14, T18 |
| C2 Product experience/trust | 01–02 | 01–07 | 01–07 | 01–04 | 01–15 | 35 | T01, T03, T04, T05, T14, T15, T17, T19 |
| C3 UX test coverage | — | 01–04 | 01–05 | 01–03 | 01–03 | 15 | T08 ve T01–T19 kabul otomasyonu |
| **Toplam** | **16** | **105** | **213** | **120** | **100 + 12 lot-öneksiz** | **566** | **Eksik atama yok** |

### 2.2 Doğrulama kararları

- `V3`: A7-P0-01 mekanizması doğru fakat etkin önem **P2**; B5-P0-01/A7-P1-01 aynı köktür ve etkin önem **P1**. Account deletion sırasında geri navigasyon, kapalı Cubit'e `emit` ve başlangıçta pending-cleanup resume eksikliği birlikte çözülmelidir.
- `V4`: B1-P0-01 taşması gerçektir fakat varsayılan ölçekte değil; %200+ metin ve dar görünümde görülür. Etkin önem **P1**, T06/T12 kabul maddesidir.
- `V5`: Taslak legal içerik doğrulanmıştır ve production gate mevcuttur; yayın kapısı **P0** kalır. Varsayılan Flutter ikon/splash doğrulanmıştır; bu plan store/release kapısı olarak **P1** izler. Finansal sorumluluk reddi eksikliği doğrulanmıştır; metin legal onay bağımlılığıyla T01'dedir.
- GPT verifier: 40 valid/confirmed, 18 partial, 2 disputed ve 1 invalid kayıt korunmuştur. `UXC-F05` ürün/tool kusuru değildir; yalnız rapor link biçimi bakım notudur.
- Runtime bekleyen iddialar: `UXF-FOUND-005`, `UXP-F06`, `UXP-F08` görsel overlap, `UXP-F10`, `UXP-F11` AT davranışı, `UXC-F03`, `UXF-F19`, `GAP-004` Favorites cihaz persistence, `GAP-006`, `GAP-007` ve `VFX-001`. Bunlar ölçülmeden “cihazda gözlendi” diye kapatılamaz.

## 3. P0/P1 yayın kapıları

| Kapı | Program | Başlangıç durumu | Yayını açan kanıt |
|---|---|---|---|
| G0 Legal ve disclosure | T01 | **BLOCKED** | Legal owner imzalı final TR/EN privacy + KVKK + finansal disclosure/Terms kararı, yeni version/hash, draft-marker CI gate ve iki dil legal-update testi |
| G1 Recovery | T02 | Açık | Startup/config/assets/scenarios fault injection; blank/fake-empty yok; kalıcı retry ready'ye döner ve eski veri ezilmez |
| G2 Finansal invariant | T03 | **Kısmi** | loss/neutral/profit, malformed rank/symbol/date/Decimal matrisi; invalid sonuç save/share edilemez |
| G3 Share parity | T04 | Açık | Beş journey'de ekran, kart ve metin aynı immutable snapshot'ı; simülasyon/fiyat/disclosure ve partial inflation korunur |
| G4 Replay iradesi | T05 | Açık | Dört tipte preview + onay + current policy; blocked durumda network ve quota sıfır |
| G5 Erişilebilir kritik yol | T06 | Açık | 320/360dp, TR/EN, light/dark, %100/%200/%300; AA, 48dp, ad/rol/state, focus/live ve allocation alternatifi |
| G6 Native marka | T07 | **Kısmi** | Branded iOS/Android launcher, adaptive + monochrome, light/dark launch ve store/device görsel onayı |
| G7 Release kanıtı | T08 | Açık | Android emulator + iOS simulator kritik yol; RC gerçek cihaz share/native smoke; saklanan screenshot/semantics/log |

## 4. Kök programlar ve kabul ölçütleri

### T01 — P0 — Legal yayın bütünlüğü ve finansal disclosure

**Kapsam:** `UXF-FOUND-001`; A1-P0-01, A7-P1-07/08, B3-P0-01, C2-P0-01/02 ve ilgili legal/l10n/test bulguları.

**Aksiyonlar:**

- Legal/product sahibi dört mevcut belgenin final TR/EN metnini, sürümünü ve hash'ini onaylar.
- “Yatırım tavsiyesi değildir”, “geçmiş performans geleceği garanti etmez”, veri/fiyat/komisyon kapsamı ve Terms of Use ihtiyacı için tek karar kaydı çıkarılır.
- Onaylanan kısa disclosure bütün finansal sonuç ve share projection'larına bağlanır; uzun metin Settings/Onboarding legal yüzeyinde sürümlenir.
- `verify_legal_release_approval.py` draft marker yanında onaylı bundle version/hash ve zorunlu belge/disclosure anahtarlarını fail-closed kontrol eder.
- Legal-update-only akışı TR/EN test edilir; kullanıcıya neyin değiştiği ve geçerlilik tarihi gösterilir.

**Kabul:** Kullanıcı hiçbir kanalda “taslak/yayınlanmamalı” metni görmez; onaysız değişiklik production tag'ini durdurur; legal copy mühendislik varsayımı içermez.

### T02 — P1 — Dürüst ve geri kazanılabilir async/dependency yüzeyi

**Kapsam:** `UXF-FOUND-002`, `UXF-F01/02/09/15`, `UXP-F01/05`, `GAP-002/005`; A1 startup, A2/A3/A4 katalog, A6 scenario/favorite, B4 error/empty/offline bulguları.

**Aksiyonlar:** ortak `loading / empty / failed / degraded / ready` sözleşmesi; kalıcı lokalize hata; in-place retry; gerçek empty ile failure ayrımı; field değişiminde eski hata temizliği; config fallback banner + retry; storage read başarısızken overwrite engeli; search-empty CTA; çevrimdışı/timeout/5xx mesaj ayrımı.

**Kabul:** hiçbir kritik dependency hatası blank veya sahte-empty üretmez; retry aynı state machine'i ready'ye getirir; başarısız read sonrasında kullanıcı verisi yazılarak ezilmez.

### T03 — P1 — Finansal temsil ve fail-closed veri bütünlüğü

**Kapsam:** `UXF-F04/05/10`, `UXP-F07/09/15/19`; A2/A3/A4/A5 ve B3/B4/B6 finansal anlam bulguları.

**Aksiyonlar:** profit/neutral/loss üçlü modeli; request-result symbol ve tam `1..N` rank invariant'ı; boş/duplicate/fractional/out-of-order payload reddi; requested/priced date/reason ayrımı; presentation'a kadar Decimal; partial inflation'ın açık state'i; open-ended scenario snapshot tarihi; schema/version guard ve migration.

**Kabul:** sıfır yeşil “kâr/yükseliş” değildir; bozuk payload kazanan üretmez; exact değer, tarih ve veri varlığı ekran/save/share/replay boyunca değişmez.

**19 Ağustos uygulama durumu:** `FinancialOutcome` loss/neutral/profit modeli ve merkezi tema/paylaşım sunumu What-if, Reverse What-if, DCA, Comparison ve Portfolio sonuçlarına bağlandı. Exact zero artık gri, `trending_flat`, işaretsiz ve “Değişim Yok / No Change” olarak gösteriliyor. Comparison parser/repository boş sonuç, fractional/duplicate/out-of-order rank ve eksik/fazla/duplicate symbol payload'larını fail-closed reddediyor. Unit/widget/repository kapsamı eklendi. Requested/priced date ayrımı, uçtan uca Decimal, partial-inflation state'i ve schema/migration maddeleri açık olduğundan G2 kapanmış sayılmaz.

### T04 — P1 — Share artifact doğruluğu ve erişilebilir önizleme

**Kapsam:** `UXF-F06/07`, `GAP-006`; A8'in tamamı, A2/A3/A4/A5 share kayıtları ve C2 paylaşım güveni.

**Aksiyonlar:** tek immutable presentation projection; simülasyon dili; veri/fiyat tarihi; komisyon/vergi kapsamı ve onaylı disclosure; partial real/cumulative parity; privacy için tutarı gizleme; iPad `sharePositionOrigin`; 9:16 karar/şablon; ölçeklenen metinsel özet veya zoom; beş kartta TR/EN light/dark golden ve gerçek PNG testi.

**Kabul:** önizleme, PNG ve paylaşım metni aynı snapshot'ı anlatır; DCA gerçekleşmiş işlem iddia etmez; mevcut reel veri düşmez; iPad share exception üretmez.

### T05 — P1 — Replay iradesi, availability, entitlement ve kota

**Kapsam:** `UXF-FOUND-003`, `UXF-F14/20/21`, `UXP-F03/04`, `GAP-001`; A6 replay, B4/B5 feature-gate ve C2 kota/paywall bulguları.

**Aksiyonlar:** senaryo tap'inde önce detay/etkilenecek form/tahmini kredi, sonra açık onay; dört tipte current tier/history/feature/quota preflight; feature/share flags için tek policy; `resetAt` ve kalan hakkı görünür recovery; upgrade yolu olmayan premium metnini kaldırma veya gerçek kanal sağlama; mevcut formu ezmeden önce onay/koruma.

**Kabul:** kullanıcı onayı öncesi calculate yoktur; blocked durumda request/quota sıfırdır; replay sonucu, ret nedeni ve geri dönüş yolu görünürdür.

### T06 — P1 — Erişilebilir kritik görev ve finansal sonuç

**Kapsam:** `UXF-F03/08/12/16`, `UXP-F08/11`, `UXP-F12` accessible-name bölümü, `GAP-003`; B1'in tüm kayıtları ve diğer raporlardaki a11y kayıtları.

**Aksiyonlar:** AA semantic color token'ları; CTA kontrastı; icon-only eylemlerde lokalize ad/state ve 48dp; adaptive `MetricRow`; sonuç başına focusable heading ve tek live announcement; animation sırasında stabil semantics; chart/allocation metin tablosu; header/date/picker rolleri; keyboard focus zinciri; reduce-motion.

**Kabul:** kritik akış WCAG 2.2 AA hedeflerinde ve %200 metinde tamamlanır; bilgi yalnız renkle verilmez; screen reader sonuç, hata, yükleme ve undo'yu bir kez ve anlamlı sırada duyar.

### T07 — P1 release gate — Native ürün kimliği

**Kapsam:** `UXC-F01`; A1-P0-02, B8-P0-01 ve splash/app-icon/store kayıtları.

**Aksiyonlar:** onaylı `Saydin-Production-Asset-Pack` kaynaklarından iOS icon slotları; Android legacy launcher, adaptive foreground/background ve API 33 monochrome; light/dark launch yüzeyleri; Android 12+ splash; manifest round icon; checksum ve boyut denetimi; simulator/device mask ve app-switcher görüntüsü.

**Kabul:** hiçbir Flutter şablon görseli kalmaz; iOS ikonları opaque/doğru boyutlu, Android safe zone geçerli; cold start ve app switcher markalıdır.

**19 Ağustos uygulama durumu:** Kaynak master'lar checksum/provenance kaydıyla `assets/branding/` altına alındı. On beş iOS icon slotu, beş Android legacy density ikonu, adaptive foreground/background, API 33 monochrome, round icon ve light/dark launch yüzeyleri üretildi. Boyut, alpha, checksum ve XML bağlantıları otomatik testte doğrulandı. iPhone 17 Pro simulator build/install/launch smoke'unda light/dark launch ve home-screen maskesi görsel olarak geçti. Android resource derlemesi/emulator ve gerçek cihaz/store preview kanıtı ortamda Java/Android SDK bulunmadığı için açık; bu nedenle G6 kapanmış sayılmaz.

### T08 — P1 kalite kapısı — Runtime ve release deneyimi kanıtı

**Kapsam:** `UXC-F02`; C3'ün tüm kayıtları, C1-P1-02, B1-P1-08, A2/A3/A4/B5 test boşlukları.

**Aksiyonlar:** assertion'sız testleri gerçek beklentilere çevirme; ana dört sayfa widget state matrisi; semantics guidelines; dark/empty/error/share goldens; Android+iOS integration journey; RC gerçek cihaz smoke; screenshot/semantics/overflow/exception artifact saklama; presentation coverage alt kapısı.

**Kabul:** G0–G6 yalnız statik değişiklikle değil, iki platformda tekrar üretilebilir kanıtla kapanır.

### T09 — P2 — Son kullanıcı niyetini koruyan async sıralama

**Kapsam:** `UXF-F13`, `UXP-F02/14`, `GAP-004`; settings, favorites, locale refresh, scenario save/load/delete ve portfolio locale-during-request yarışları.

**Aksiyonlar:** alan-bazlı mutation veya queue/revision/latest-wins; stale completion guard; çift gönderim kilidi; controlled interleaving testleri; reload sonrasında son niyet doğrulaması.

**Kabul:** tamamlanma sırası ne olursa olsun UI ve persistence son kullanıcı niyetini taşır; stale operation feedback üretmez.

### T10 — P2 — Geri alınabilir/yıkıcı eylem ve kalıcı recovery

**Kapsam:** `UXF-FOUND-004`, `UXP-F12/16` delete bölümü; A4 reset/remove, A6 delete/undo, A7 account/reset ve B5 destructive-flow kayıtları.

**Aksiyonlar:** portfolio remove/reset undo veya açık onay; scenario için görünür delete; kalıcı işlem/recovery status; account deletion sırasında `PopScope`; kapalı Cubit `emit` koruması; reset olayını başarı state'inden sonra üretme; app startup'ta pending local cleanup resume; işlem bazlı hata ve retry.

**Kabul:** geri dönüşsüz eylem tek kazara dokunuşla olmaz; app lifecycle terminal sonucu yutmaz; pending cleanup yeniden DELETE göndermeden tamamlanır.

### T11 — P2 — Scenario/portfolio veri, persistence ve ölçek sağlamlığı

**Kapsam:** `UXP-F07/13`; A4 ve A6 schema, persistence, partial result, retry, portfolio fan-out ve senaryo ayırt edilebilirliği kayıtları.

**Aksiyonlar:** draft persistence kararını açık ürün sözleşmesine bağlama; bozuk nested veriyi kart bazında izole etme; schema migration; bounded concurrency; item progress/cancel/failed-only retry; senaryo ad/notu, içerdiği varlıklar ve sonuç özeti; sort/filter/search; duplicate/version davranışı.

**Kabul:** tek bozuk legacy kayıt listeyi düşürmez; 20 kalem kontrollü çalışır; kısmi hata doğru görünür ve yalnız başarısız kalem yeniden denenir; kullanıcı kayıtları sahte-empty görünmez.

### T12 — P2 — Adaptif düzen, hareket, semantics ve performans sistemi

**Kapsam:** `UXF-FOUND-005/006`, `UXF-F18/19`, `UXP-F06/10/11/17`, `UXC-F03`, `GAP-007`, `VFX-001`; B7 ve B8 responsive/motion/performance bulguları.

**Aksiyonlar:** breakpoint/max-width/NavigationRail; scroll-safe sheet ve keyboard inset; SafeArea; adaptive amount/metric/scenario/settings layouts; merkezi motion policy; lazy tab construction; chart downsampling/RepaintBoundary; system UI style; predictive/root back; rotation/split-view state koruması.

**Kabul:** 320dp–tablet, portrait/landscape, keyboard ve %300 matrisi overflow/exception üretmez; reduced motion korunur; ilk açılış kullanılmayan dört sayfayı eager yüklemez.

### T13 — P2 — Tasarım sistemi, tema ve component standardı

**Kapsam:** `UXP-F17/18`, `UXC-F04`, `GAP-008`; B2'nin tüm kayıtları, hardcoded renk/snackbar/sheet/result-card kayıtları.

**Aksiyonlar:** semantic `ThemeExtension`; typography/spacing/radius/elevation/motion token'ları; component themes; ortak MetricRow/AppErrorView/sheet/snackbar/result-card/asset-picker aileleri; share token kaynağı; dark token lint/golden; `docs/design-system.md`.

**Kabul:** kullanıcıya görünen state aynı kavram için tek anatomi ve semantic token kullanır; dark mode sabit light palette içermez.

### T14 — P2/P3 — Yerelleştirme, mikro-kopya ve içerik yönetişimi

**Kapsam:** `UXF-F17`, `UXC-F06`; B3'ün legal dışındaki tüm kayıtları ve diğer lotlardaki terminoloji/kopya kayıtları.

**Aksiyonlar:** TR/EN terminoloji sözlüğü; “kâr” yazımı ve kavram adları; resmi hitap; locale-aware tarih/para/casing/search; actionable error copy; limitlerin kodla bağlı ICU mesajları; kritik ARB description/context; unused/duplicate key temizliği; içerik review/version süreci.

**Kabul:** aynı finansal kavram aynı dilde tek ad taşır; tarih/para cihaz ve uygulama locale'ine göre doğrudur; kullanıcı mesajı ne olduğunu ve sonraki eylemi söyler.

### T15 — P2 — Bilgi mimarisi, navigasyon ve ilk değer anı

**Kapsam:** B5'in destructive-flow dışındaki tüm kayıtları; A1 onboarding, A6 scenario navigation ve C2 değer önerisi kayıtları.

**Aksiyonlar:** root back sözleşmesi; feature-gated tab modeli; dar ekranda kısa etiket/NavigationBar; doldurulmuş modal dismiss guard; formdan forma veri köprüleri; replay context/return; onboarding'i kısaltma ve canlı örnek; favorites/verilerim/about keşfedilebilirliği; deep-link kararı.

**Kabul:** geri eylemi önce sekme/akış bağlamını çözer; kullanıcı mevcut girdisini sessizce kaybetmez; ilk kullanılabilir simülasyona giden yol ölçülür ve kısalır.

### T16 — P2 — Form, girdi ve doğrulama sözleşmesi

**Kapsam:** B6'nın tamamı; A2/A3/A4 inline validation, amount/date/search/sheet kayıtları ve `GAP-007`.

**Aksiyonlar:** locale-aware paste/decimal parser; caret koruma; locale değişiminde güvenli reformat; alanla ilişkili typed hata ve düzeltince temizleme; min/max/helper; date-order client guard; sessiz amount-type/tarih resetini kaldırma; keyboard actions; clear/quick amount/date presets; draft preservation.

**Kabul:** geçerli giriş yazarken bozulmaz; yanlış alan odaklanır ve özgül mesaj verir; geçersiz tarih backend'e gitmez; klavye formun CTA'sını kapatmaz.

### T17 — P1/P2 — Settings, account deletion, privacy ve destek yüzeyi

**Kapsam:** A7'nin legal dışındaki tüm kayıtları; B8 privacy/platform ve C2 support/about bulguları.

**Aksiyonlar:** account deletion lifecycle T10 ile; TR onay kelimesine alan-özel tolerans ve helper/error; backend/local-cleanup hata ayrımı; hangi verinin silindiği; işlem progress/live state; Preferences reset undo; aktif system theme/language; About/version/licenses/support/privacy dashboard; `PrivacyInfo.xcprivacy` envanteri.

**Kabul:** silme hakkı klavye/locale nedeniyle sessiz kilitlenmez; kullanıcı remote/local sonucu ayırt eder; destek diyen her mesaj gerçek kanala bağlanır.

### T18 — P2/P3 — Dokümantasyon ve ürün kalite yönetişimi

**Kapsam:** C1'in tüm kayıtları; `UXP-F18`, `UXC-F04`, `GAP-008`; B3 translator context ve review governance.

**Aksiyonlar:** architecture delete/theme/Settings lifecycle drift düzeltmesi; a11y standardı; design/content guide; UX ADR'ları; `.coderabbit.yaml` dependency yönü; geliştirme/skill checklist'lerinde a11y/l10n/responsive/test; analiz artefact saklama politikası; kullanıcıya dönük içerik onayı.

**Kabul:** aktif doküman kaynak kodun tersini öğretmez; UI PR'ı için uygulanabilir, otomatikleşmiş bir Definition of Done vardır.

### T19 — P3/fırsat — Açıklanabilir karar desteği ve ürün farklılaştırma

**Kapsam:** `UXF-F11`, `UXF-FO01/02/03`, `UXP-F16` edit/rename; A1–A8/B1–B8/C1–C3 içindeki 112 fırsat başlığının tamamı ve C2 ürün/retention önerileri.

**Aksiyonlar:** “Nasıl hesaplandı?”; DCA alım dökümü ve lump-sum kıyası; Comparison fark/gerekçe/grafik; data coverage preset; portfolio katkı/en iyi-en kötü; senaryo ad/not/takip; hazır örnekler; doğal dil özeti; yardım/sözlük; privacy-safe analytics; share/deep-link/QR; widget/quick actions yalnız ürün kararıyla.

**Kabul:** her fırsat ayrı discovery hipotezi, başarı metriği ve privacy değerlendirmesi almadan build backlog'una girmez; P0/P1 kapasitesini tüketmez.

## 5. Uygulama sırası

### Dalga 0 — dış bağımlılığı görünür kıl

- [ ] T01 legal owner ve product owner; onaylı dört belge + disclosure/Terms kararını teslim eder.
- [ ] Legal sign-off artifact'i version/hash ile güncellenir; G0 dry-run kanıtı alınır.
- [x] Mevcut fail-closed draft marker release gate'inin varlığı doğrulandı.

### Dalga 1 — hemen uygulanabilir release kapıları

- [~] **T07:** native iOS/Android varlıkları, metadata ve otomatik doğrulama tamamlandı; iOS light/dark simulator smoke geçti. Android emulator/gerçek cihaz ve store preview kanıtı açık.
- [~] **T03:** neutral getiri ve Comparison rank/symbol fail-closed invariant'ları ile unit/widget/repository testleri tamamlandı; date/Decimal/partial/schema alt işleri açık.
- [ ] **T04:** share snapshot/disclosure modeli ve iPad anchor; beş kart parity testi.
- [ ] **T02:** onboarding blank, katalog ve scenario failure için kalıcı retry; fake-empty ayrımı.
- [ ] **T05:** otomatik replay calculate'ı preview/onay arkasına al; policy preflight.
- [ ] **T06:** CTA kontrastı, icon name/48dp, allocation alternatifi, result focus/reflow.
- [ ] **T08:** yukarıdaki değişikliklere en küçük Android+iOS kritik yol gate'i.

### Dalga 2 — ortak P2 sistemleri

- [ ] T09 async sequencing; T10 yıkıcı/recovery; T11 schema/portfolio scale.
- [ ] T12 adaptive/motion/performance; T13 design tokens/components.
- [ ] T14 l10n/content; T15 navigation/IA; T16 forms; T17 settings/privacy; T18 docs governance.

### Dalga 3 — fırsatlar

- [ ] T19 discovery, ölçüm ve ürün kararı sonrası parçalara ayrılır.

## 6. Yüksek kaldıraçlı kabul matrisi

| Matris | Varyantlar | Geçiş koşulu |
|---|---|---|
| Dependency recovery | startup/config/assets/scenarios × offline/timeout/5xx/empty/retry-success | Blank/fake-empty yok; kalıcı açıklama ve retry; veri ezilmez |
| Financial invariants | loss/zero/profit × empty/fractional/duplicate/out-of-order ranks × Decimal extremes × requested/priced date | Invalid fail-closed; neutral doğru; UI/save/share tek exact snapshot |
| Share parity | 5 journey × TR/EN × nominal/real/partial × adjusted/open-ended date | Görsel/metin aynı projection; simülasyon, fiyat ve disclosure okunur |
| Replay policy | 4 type × free/premium/fallback × feature on/off × quota available/exhausted | Onay öncesi calculate yok; blocked request/quota sıfır |
| Accessible path | 320/360/tablet × TR/EN × light/dark × %100/%200/%300 × keyboard/AT/reduced motion | Overflow/exception yok; 4.5:1; 48dp; tekil ad/rol/state; result heading ve allocation okunur |
| Async interleaving | completion sırası × success/failure × theme/language/favorite/scenario | State, persistence ve reload son niyette |
| Native smoke | iPhone/iPad + Pixel/Samsung × launcher/cold-start/app-switcher/share | Marka maskesi/splash doğru; exception yok; release artifact'i saklı |

## 7. Dış kararlar ve sahiplik

| Karar/çıktı | Blokladığı program | Önerilen sahip |
|---|---|---|
| Final privacy/KVKK, disclosure ve Terms kararı | T01, T04 | Legal + Product |
| Brand safe-zone/store preview onayı | T07 | Brand/Design + Mobile |
| Comparison response/date-adjustment sözleşmesi | T03 | Backend + Mobile |
| Tier/history/quota/replay decision table | T05 | Product + Backend |
| A11y token/breakpoint/motion standardı | T06, T12, T13 | Design system + Mobile |
| Scenario schema/migration politikası | T03, T11 | Backend + Mobile |
| Simulator/emulator/gerçek cihaz erişimi | T08 | Platform/CI |

## 8. Definition of Done

Bir madde ancak aşağıdakilerin tamamı sağlandığında `[x]` olur:

1. Kaynak bulgu ID'leri ve varsa duplicate/partial/disputed notu PR veya commit açıklamasında bulunur.
2. TR ve EN metinleri, light/dark tema ve ilgili responsive varyantlar kapsanır.
3. State, semantics ve finansal invariant testleri yalnız “crash olmadı” değil kullanıcıya görünen sonucu assert eder.
4. Static analyze + ilgili unit/widget/golden/integration testleri geçer.
5. Runtime-only iddia için gerçek simulator/device kanıtı saklanır; statik çıkarım runtime sonucu gibi yazılmaz.
6. `docs/analysis/ux-action-plan.md` durum ve kanıt bağlantısıyla güncellenir.

## 9. Uygulama günlüğü

### 19 Ağustos 2026

- İki review ağacındaki bütün ana rapor, verifier ve prioritization kayıtları okundu; 566 Claude başlığı ve 64/64 GPT source ID kapsam defterine alındı.
- Ham severity ile doğrulanmış severity arasındaki çelişkiler yukarıdaki kararlarla çözüldü.
- Production asset pack'in README, manifest, checksum ve QA raporu incelendi; “01 / Zaman İzi” onaylı kimlik kaynağı olarak seçildi.
- T01'in içerik bağımlılığı nedeniyle engineering tarafından uydurma legal metinle kapatılmaması kararlaştırıldı.
- T07 native marka dilimi uygulandı: onaylı raster master'lar provenance/checksum kaydıyla `assets/branding/` altına alındı; iOS AppIcon/LaunchImage/LaunchBackground ve Android legacy/adaptive/monochrome/Android 12+ light-dark splash kaynakları yenilendi.
- T07 otomasyonu eklendi: `tool/tests/test_brand_assets.py` kaynak hash'lerini, bütün slot/density boyutlarını, opacity'yi ve native XML bağlantılarını doğruluyor; 4/4 test geçti. `ibtool` ve `actool` doğrulamaları geçti; `flutter build ios --simulator --debug` başarılı oldu.
- T07 runtime smoke: iPhone 17 Pro simulator'a kurulum/launch başarılı; açık ve koyu launch yüzeyleri ile home-screen ikon maskesi görsel olarak doğrulandı. Android Gradle doğrulaması Java/Android SDK bulunmadığından alınamadı; statik resource/XML testi geçti ve gerçek cihaz/store preview açık bırakıldı.
- T03 ilk dilimi uygulandı: ortak loss/neutral/profit modeli ve tema sunumu beş sonuç ailesine bağlandı; exact zero artık kâr sayılmıyor, pozitif işaret almıyor ve iki dilde nötr metin/renk/ikon kullanıyor.
- T03 Comparison sınırı sertleştirildi: boş/fractional/duplicate/out-of-order rank ve request ile uyuşmayan eksik/fazla/duplicate symbol response'ları reddediliyor. Bozuk sonuçların UI/share/save hattına ilerlemesi bu katmanda durduruldu.
- Doğrulama: `flutter analyze` temiz; 74 hedefli test ve Git tarafından izlenen Flutter testlerinin tamamı (556) geçti; brand/ARB/repository Python denetimleri 15/15 geçti; ARB sözleşmesi 268 mesaj, repository sözleşmesi 918 bağlantı ile geçti; `git diff --check` temiz.
- Kullanıcıya ait, önceden untracked `test/_verify_v1/` ve `test/_verify_v2/` runtime probe'larına dokunulmadı. Bu probe'lar ham `flutter test` keşfinde bilinçli timeout/diagnostic davranışı gösterdiği için regression kanıtı Git tarafından izlenen 556 test üzerinden alındı.
