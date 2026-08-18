# Saydın.Client — Review bulguları remediation aksiyon planı

**Başlangıç:** 2026-08-18
**Çalışma branch'i:** `development`
**Baseline:** `development == main == 441eda4b5209f7814345eede1cb64438174ca6f2`
**Kapsam:** Review raporlarındaki 69 kayıt; çapraz lens tekrarları ortak iş paketlerinde birleştirilmiştir.

## Durum sözlüğü

| Durum | Anlam |
|---|---|
| `IN_PROGRESS` | Atanmış ve uygulaması başlamış iş |
| `PLANNED` | Bağımlılık sırasına yerleştirilmiş iş |
| `AWAITING_EXTERNAL` | Marka, hukuk veya backend gibi repo dışı doğrulama/girdi gerekiyor |
| `VERIFICATION_EXTERNAL` | Repo uygulaması/testi tamam; gerçek backend, Sentry veya store ortamında kanıt gerekiyor |
| `DEFERRED_BY_USER` | Risk kullanıcı kararıyla bu tur için açık bırakıldı; düzeltilmiş sayılmaz |
| `VERIFICATION` | Kod tamamlanmış olsa da tüm yerel test/review kanıtı bekleniyor |
| `DONE` | Kod, test, doküman ve bağımsız review kabul kriterleri tamamlandı |

## Çalışma prensipleri

1. Bütün değişiklikler yalnız `development` branch'inde yapılır.
2. Önce yanlış sonuç, veri hakkı, privacy ve crash riskleri kapatılır; kozmetik ve bakım işleri sona bırakılır.
3. Her davranış düzeltmesi aynı PR/diff içinde deterministik regresyon testiyle korunur.
4. Bir finding başka bir finding ile aynı kök nedense tek implementasyon yapılır, fakat iki ID de doğrulama matrisinde kapanır.
5. Agent'lar çakışmayan dosya kümelerinde çalışır. Ortak dosya gereksinimi ana ajan tarafından sıralanır.
6. Hukuki kimlik, adres, KEP, store credential, production host veya backend contract uydurulmaz.
7. Repo dışı yetki, hukuk, marka veya backend kararı gerektiren riskler “fixed” sayılmaz; kabul edilmiş teknik borç olarak görünür kalır.

## Karar kaydı

### ADR-R01 — Onboarding atlanabilir kalacak

`UX-04` için ürün kararı, kullanıcının onboarding'i atlayabilmesidir. Ancak
“atlama” görülmeyen bir legal metnin kabulü olarak kaydedilmeyecektir. Legal
metinler Settings üzerinden erişilebilir kalacak; sürüm/acknowledgement kaydı
yalnız tasarlanan açık legal adımda yazılacaktır.

### ADR-R02 — Senaryo silmede erişilebilir confirmation kullanılacak

Mevcut backend sözleşmesinde güvenilir restore endpoint'i olmadığı için sahte
bir “Undo” sunulmayacaktır. `UX-06` çözümü; swipe öncesi confirmation,
kart üzerinde ekran okuyucu/klavye ile erişilebilen görünür silme aksiyonu ve
başarı/hata durumunun doğru duyurulmasıdır. Restore API eklenirse süreli Undo
ayrı geliştirme olarak değerlendirilebilir.

### ADR-R03 — Account deletion remote-first ve idempotent olacak

`SEC-03` ve `UX-12` için device identity, backend silme kabul edilmeden yok
edilmeyecektir. İstemci yalnız 200/204 sonrasında local cleanup yapar;
network/202/4xx/5xx halinde kimlik ve yerel veri korunur, retry mümkün kalır.
Lost-response/idempotency sözleşmesi backend ile doğrulanana kadar SEC-03
`VERIFICATION_EXTERNAL` durumundadır.

### ADR-R04 — Finansal sonuçlar immutable request snapshot'a bağlı olacak

`FIN-01–04` için form state'i ile sonuç state'i karıştırılmayacaktır. Her sonuç
kendisini üreten immutable request snapshot, request ID ve completeness/dirty
durumunu taşır; stale cevaplar emit edilmez; partial sonuç açıkça gösterilmeden
kaydedilemez veya paylaşılamaz.

### ADR-R05 — Coverage bir anda keyfi eşiğe yükseltilmeyecek

`QE-02` için önce generated dosyaları dışlayan, bütün production dosyalarını
denominator'a dahil eden gerçek baseline tanımlanacaktır. CI mevcut normalize
baseline'ın altına düşmeyi ve yetersiz patch coverage'ı engelleyecek; ardından
test dalgalarıyla `%60+` seviyesine monoton yükseltilecektir.

### ADR-R06 — Legal metin teknik olarak doğrulanacak, hukuk onayı taklit edilmeyecek

`UX-01/SEC-04` kapsamında uygulamanın gerçek data flow'u TR/EN metinlere
yansıtılır. Tüzel kişi, adres, KEP, hukuki dayanak ve yurtdışı aktarım gibi
bilinmeyen alanlar uydurulmaz. Teknik draft iki farklı modelle bağımsız review
edilir; nihai `DONE` için yetkili hukuk/DPO sign-off gerekir.

## Dalga 0 — Güvenli başlangıç ve dış girdiler

| Paket | Finding'ler | Durum | Aksiyon | Kabul kanıtı |
|---|---|---|---|---|
| W0-01 Branch baseline | Program geneli | `DONE` | `development`, güncel `main` commit'inden oluşturuldu | İki ref aynı SHA |
| W0-02 Legal truth alignment | UX-01, SEC-04 | `AWAITING_EXTERNAL` | Teknik data inventory, doğru TR/EN metin, content-bound release gate ve iki bağımsız review tamamlandı | Yetkili hukuk/DPO sign-off ve eksik kurumsal/operasyonel alanlar |
| W0-03 Marka asset'i | UX-02 | `AWAITING_EXTERNAL` | Onaylı logo/app-icon master dosyalarını iOS ve Android setlerine uygula | iOS 1024, Android adaptive/monochrome, store ve cihaz QA |
| W0-04 Production governance | SEC-01, SEC-02, SEC-07, SEC-09, SEC-10, SEC-18 | `DEFERRED_BY_USER` | Branch/environment governance, gerçek ortam origin'leri, Action SHA pinleme, certificate pinning ve native release testleri bu turda bilerek değiştirilmedi | Owner-approved GitHub/release configuration ve gerçek cihaz/artifact evidence |

## Dalga 1 — Yanlış sonuç, privacy ve crash sınırı

Bu dalga production doğruluğu için en yüksek önceliktir. Ortak dosyalara
dokunan işler ana ajan kontrolünde küçük, doğrulanabilir dilimler halinde
başlatılmıştır.

| Paket | Finding'ler | Durum | Aksiyon | Kabul kanıtı |
|---|---|---|---|---|
| W1-01 Finansal P1 | FIN-01–FIN-07 | `DONE` | Partial/dirty/snapshot modeli, stale-response rejection ve crash sınırları uygulandı | Unit/BLoC/widget regresyon testleri |
| W1-02 Account ve telemetry core | SEC-03, SEC-05, SEC-12, SEC-13, SEC-20, UX-12 | `DONE` / `VERIFICATION_EXTERNAL` | Remote-first deletion, durable cleanup phase, backend tekrar etmeyen local retry, tüm session BLoC ağacı reseti, deny-by-default scrub, awaited bootstrap, neutral 403/404 ve merkezi endpoint tamamlandı | Yerel state-machine/DI reset testleri geçti; SEC-03 lost-response/idempotency backend smoke bekliyor |
| W1-03 Config readiness | UX-03 | `DONE` | Explicit loading/ready/fallback state ve startup gate uygulandı | Free/premium cold-start/fallback testleri |
| W1-04 Legal UX | UX-04, UX-05 | `DONE` | Skip implicit acceptance yazmıyor; notice kaydı, hash/version comparison ve re-prompt uygulandı | Skip/acknowledgement/version-upgrade widget ve repository testleri |
| W1-05 Destructive ve responsive UX | UX-06, UX-07 | `DONE` | Erişilebilir confirm/delete; scroll/inset/text-scale güvenli ekranlar | 320dp, 200% text, keyboard ve semantics testleri |
| W1-06 Release quality dependency | QE-01 | `DONE` | Release exact tag SHA için başarılı CI run'ı olmadan ilerlemiyor | Workflow guard ve parse/contract kontrolleri |
| W1-07 Release observability | SEC-06 | `VERIFICATION_EXTERNAL` | Release DSN/credential fail-closed; Android mapping, iOS/Flutter symbol upload ve release/dist bağı tamamlandı | Production-like canary symbolication ve gerçek environment secret'ları bekliyor |

## Dalga 2 — Finansal ve güvenlik sözleşme doğruluğu

| Paket | Finding'ler | Durum | Aksiyon | Kabul kanıtı |
|---|---|---|---|---|
| W2-01 Decimal request boundary | FIN-08, QE-04 | `DONE` / `VERIFICATION_EXTERNAL` | Money hattı Decimal/canonical string; agent sözleşmeleri aynı tek kaynağa alındı | TR/EN exact round-trip geçti; backend decimal-string binder staging smoke bekliyor |
| W2-02 Tarih ve nullable invariant'ları | FIN-09–FIN-12 | `DONE` | Nullable clear, calendar-month clamp, ortak range validator ve asset intersection uygulandı | Ay sonu/no-overlap/clear/symbol-change testleri |
| W2-03 API ve outcome semantiği | FIN-13–FIN-15, SEC-13 | `DONE` | Malformed 2xx, typed per-item error ve doğrulanmış/türetilmiş `isProfit` sözleşmesi | Repository/model contract test matrisi |
| W2-04 Scenario replay | FIN-18 | `DONE` | Versioned DTO→command mapper; schema, katalog, limit, duplicate, tarih ve feature-flag doğrulamaları | Legacy/current/future ve bozuk payload rejection testleri |
| W2-05 API URL ve export gerçeği | SEC-08, SEC-11 | `DONE` | Eager origin validation; doğrulanmamış export endpoint iddiası kaldırıldı, legal başvuru kanalıyla hizalandı | URL authority matrisi ve doküman contract testleri; host ayrımı SEC-02 altında ertelendi |
| W2-06 Dependency ve artifact hygiene | SEC-14, SEC-15 | `DONE` | Scheduled/risk-bazlı OSV gate, Dependabot, ignore ve iki katmanlı secret scanning | Policy fixture'ları, 303 tracked file ve 134 commit taraması |
| W2-07 Release reproducibility | SEC-16, SEC-17 | `DONE` | Retry-safe metadata, checksum/SBOM/provenance/attestation ve release-safe iOS plist | Evidence generator testleri, plist parse ve workflow doğrulaması |

## Dalga 3 — Kullanıcı deneyimi, erişilebilirlik ve performans

| Paket | Finding'ler | Durum | Aksiyon | Kabul kanıtı |
|---|---|---|---|---|
| W3-01 Refresh ve feedback | UX-08, UX-13 | `DONE` | Refresh Future terminal state'e bağlı; persistence hataları lokalize/live-region bildirimli | Success/error refresh ve rollback widget testleri |
| W3-02 Tema ve finansal renk | UX-09, FIN-16 | `DONE` | Sabit finansal renkler semantic `FinancialColors` ThemeExtension'a taşındı | Light/dark WCAG ve golden testleri |
| W3-03 Semantics ve grafik alternatifi | UX-10, FIN-17 | `DONE` | Grafik özetleri, klavye ile açılan scrollable veri alternatifi ve seri tooltip'leri | Semantics, keyboard ve locale testleri |
| W3-04 Asset katalog verimliliği | FIN-02, FIN-19 | `DONE` | Locale-keyed shared cache/single-flight; locale değişiminde hesaplama tekrarı yok | Tek network çağrısı ve calculate-never testleri |
| W3-05 Maksimum paylaşım layout'u | FIN-20 | `DONE` | İlk 6 + kalan sayısı, constrained scroll preview, ellipsis ve sabit capture scale | 20 item/uzun ad/320dp/200% golden testi |
| W3-06 Test piramidi | FIN-21, QE-07 | `DONE` | State-machine, root/page, semantics, keyboard, responsive ve golden test ağı genişletildi | 537 test; native cihaz/artifact katmanı SEC-18 altında ertelendi |

## Dalga 4 — Tooling, doküman ve düşük öncelikli hardening

| Paket | Finding'ler | Durum | Aksiyon | Kabul kanıtı |
|---|---|---|---|---|
| W4-01 Doküman single-source | UX-11, FIN-24, SEC-21 | `DONE` | README/architecture/release/review branch ve gerçek davranışla eşlendi | 402 Markdown linki ve repo contract checker |
| W4-02 Agent toolchain | QE-03–QE-06 | `DONE` | Tracked master plan; Decimal/AppError uyumlu scaffold; runtime-neutral deploy skill | Pozitif/negatif contract fixture'ları |
| W4-03 Non-Dart kalite kapıları | QE-08, QE-09 | `DONE` | l10n dirty diff, actionlint, ShellCheck, YAML ve Markdown/path gate'leri | 25 quality fixture testi ve CI job'ları |
| W4-04 Device runbook | QE-10, SEC-22 | `DONE` | Simulator/fiziksel cihaz host ayrımı ve ortak debug allowlist sözleşmesi | URL/platform testleri; gerçek cihaz smoke SEC-18 kapsamında ertelendi |
| W4-05 Retry hardening | SEC-19 | `DONE` | Retry-After 30s cap, sendTimeout, typed cancellation ve injectable delay | Cancel/retry/HTTP-date testleri |
| W4-06 Result determinism | FIN-22 | `DONE` | `effectiveSellDate/calculatedAt` request snapshot'ta saklanıyor | Gece yarısı/fake-clock testleri |
| W4-07 Share resource lifecycle | FIN-23 | `DONE` | `ui.Image.dispose()` `try/finally` ile garanti edildi | Gerçek `ui.Image.debugDisposed` testi |
| W4-08 Coverage enforcement | QE-02 | `DONE` | 159 production library denominator, %47,8 project ve %50 patch gate | 537 testlik final coverage koşusunda %49,16 project / %72,82 current patch; %60+ staged hedef |

## Dış karar ve girdi listesi

Bu maddeler uygulama koduyla tek başına `DONE` yapılamaz:

1. `UX-02`: Onaylı SVG/vektör logo ve renk kararı.
2. `UX-01/SEC-04`: Gerçek veri sorumlusu tüzel unvanı, adresi, başvuru/KEP
   kanalı, hukuki dayanak, aktarım ve retention için hukuk/DPO onayı.
3. `SEC-06`: Production Sentry project/DSN/auth token, retention ve canary
   symbolication doğrulaması.
4. `SEC-03`: Backend DELETE'in lost-response/idempotency ve request identity
   semantiği. İstemci 200/204 dışındaki cevapta kimliği ve yerel veriyi korur.
5. `FIN-08`: Backend JSON binder'ın canonical decimal string kabulü için staging
   contract smoke. Precision korunacağı için sessizce `double`a geri dönülmez.
6. Kullanıcı tarafından bu tur için ertelenen SEC-01/02/07/09/10/18:
   branch/ruleset/environment approval, gerçek production/staging origin,
   Action SHA pinleme, workflow injection hardening'in kalan kısmı,
   certificate pinning ve native/artifact/device test matrisi.

## Her dalga için zorunlu kapanış kontrolü

- Değişen bütün Dart dosyaları formatlıdır.
- `flutter analyze --fatal-infos` temizdir.
- İlgili hedefli testler ve tam `flutter test` suite'i geçer.
- Generated l10n güncelse dirty diff temizdir.
- File/path/YAML/plist/XML/shell bütünlük kontrolleri geçer.
- Bulgu ID'si, regression test'i ve kabul kriteri birebir eşleşir.
- Uygulanamayan test ortam kısıtı “başarılı” diye raporlanmaz.
- `AWAITING_EXTERNAL`, `VERIFICATION_EXTERNAL` ve `DEFERRED_BY_USER` maddeler
  release notunda görünür kalır.

## İlerleme raporlama biçimi

Her uygulama turu sonunda şu format kullanılacaktır:

| Finding | Sonuç | Değişiklik | Test/kanıt | Kalan risk |
|---|---|---|---|---|
| `ID` | `DONE/VERIFICATION/...` | Dosya ve davranış özeti | Komut/test adı | Varsa dış bağımlılık |

Bu plan yaşayan bir dokümandır. Bir finding kapandığında yalnız kodun değişmiş
olması yeterli değildir; test/review kanıtı tamamlanmadan durum `DONE` olmaz.
