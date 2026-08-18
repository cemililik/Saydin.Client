# Saydın.Client — Sistematik bütün proje review'u

**Tarih:** 18 Ağustos 2026
**İncelenen commit:** `441eda4b5209f7814345eede1cb64438174ca6f2` (`main`)
**Karar:** **NO-GO — mevcut durum production/store yayını için onaylanmamalı**
**Değişiklik sınırı:** Uygulama kodu değiştirilmedi; yalnız `docs/analysis/**`
altında review çıktıları üretildi.

## Yönetici özeti

Proje; katman sınırları, typed hata omurgası, finansal sonuçlarda Decimal
kullanımı, l10n tutarlılığı ve mevcut unit/BLoC/repository test disiplini
açısından iyi bir temele sahip. İncelenen commit'in GitHub CI koşusunda format,
`flutter analyze --fatal-infos` ve **379 test başarılıdır**. Buna rağmen bu
yeşil sinyal bugün production readiness anlamına gelmez: coverage sözleşmenin
altındadır, release edilen SHA'nın CI başarısı workflow tarafından
doğrulanmaz, platform release yolu hiç çalıştırılmamıştır ve repository
koruma/production approval mekanizmaları fiilen tanımlı değildir.

Dört uzman review hattında **69 bulgu kaydı** oluşturuldu:
**2 P0, 26 P1, 33 P2, 8 P3**. Bu ham toplam bilinçli çapraz inceleme içerir;
örneğin legal metin doğruluğu ürün ve güvenlik lenslerinde, release CI kapısı
güvenlik ve quality lenslerinde ayrı etkileriyle değerlendirilmiştir. Bu nedenle
69 sayısı “69 benzersiz ticket” diye okunmamalıdır. Aşağıdaki yayın kapıları ve
yol haritası tekrar eden kök nedenleri tek iş akışlarında birleştirir.

NO-GO kararını tek başına destekleyen başlıca kümeler şunlardır:

1. Kullanıcıya sunulan gizlilik/KVKK kaynakları kendilerini template/yer tutucu
   olarak işaretliyor; veri akışı, anonimlik, uninstall ile silinme ve export
   iddiaları gerçek implementasyonla uyuşmuyor.
2. Production ve staging aynı geçici `ngrok-free.dev` origin'ine bağlı;
   production/staging GitHub environment'ları, `main` koruması ve ruleset yok;
   release workflow'u CI sonucu aramadan store job'larına ilerleyebiliyor.
3. iOS ve Android launcher asset'leri Saydın markası yerine varsayılan Flutter
   ikonudur.
4. Finansal akışlarda eksik portföy toplamının tam sonuç gibi sunulması,
   request/form state yarışları, eski sonuçla kaydetme/paylaşma ve üç doğrudan
   crash yolu vardır.
5. Backend hesap silme başarısız olsa da local secure storage ve eski device ID
   silinerek server kaydı için retry/ilişkilendirme kabiliyeti kaybedilebilir.
6. Sentry privacy scrubber küçük finansal değerleri/typed context'i geçirebilir;
   buna karşı resmî release build'lerinde Sentry DSN ve symbol upload zinciri
   hiç etkin değildir.
7. Config cold-start, onboarding legal kabulü/sürüm yenileme, geri alınamaz
   senaryo silme ve büyük metin/dar ekran akışları temel kullanıcı yolculuklarını
   güvenilmez veya erişilemez bırakabilir.

## Review kapsamı ve ajan tasarımı

Review, kritikliği ve uzmanlık ihtiyacı ayrıştırılarak dört paralel hatta
yürütüldü. Bütün tracked proje girdileri birincil bir hatta atandı; kritik
dosyalar ikincil lenslerle tekrar okundu.

| Hat | Birincil kapsam | Kayıtlı bulgu | Çıktı |
|---|---|---:|---|
| Finansal domain | What-if, comparison, DCA, portfolio; state makineleri, para/tarih doğruluğu, paylaşım ve ilgili testler | 24: 7 P1, 14 P2, 3 P3 | [01 — Finansal domain review](01-financial-domain-review.md) |
| Güvenlik/platform/teslimat | Network, error, observability, storage, account deletion, Android/iOS, dependency, CI/release/signing ve dış GitHub durumu | 22: 7 P1, 11 P2, 4 P3 | [02 — Güvenlik, platform ve teslimat](02-security-platform-delivery-review.md) |
| Ürün/UX/a11y/docs | Ürün akışları, legal/onboarding/scenarios/settings, tema, responsive davranış, erişilebilirlik, l10n, asset ve dokümanlar | 13: 2 P0, 5 P1, 5 P2, 1 P3 | [03 — Ürün, UX, erişilebilirlik ve docs](03-product-ux-accessibility-docs-review.md) |
| Quality/tooling | 44 test dosyası, coverage, `.claude/**`, scaffold/review skill'leri, l10n/CI/non-Dart kapıları ve ürün P0/P1 bağımsız doğrulaması | 10 yeni: 7 P1, 3 P2 | [04 — Quality engineering ve agent tooling](04-quality-engineering-agent-tooling-review.md) |
| **Ham toplam** | Çapraz lens tekrarları korunmuştur | **69: 2 P0, 26 P1, 33 P2, 8 P3** | [05 — 303 dosyalık kapsam manifestosu](05-review-coverage-manifest.md) |

Baseline, `git ls-files` ile alınmış **303 tracked dosyadır**. Sıralı yol
listesinin SHA-256 değeri
`d4215ba391e261bedbb1fc5d7f0b7368dd68e91708eefddea9a57f8328967211`'dir.
Manifestoda her dosya; review sahibi, varsa ikincil lens ve inceleme biçimiyle
tek tek kayıtlıdır. Görseller görsel/metadata olarak, wrapper JAR bütünlük ve
checksum zinciriyle, diğer girdiler satır/statik/sözleşme düzeyinde ele alındı.

## Öncelik modeli

| Seviye | Ana rapordaki anlam |
|---|---|
| P0 | Store/production yayınını doğrudan durduran doğrulanmış uyumluluk veya ürün bütünlüğü engeli |
| P1 | Yanlış finansal bağlam, crash/race, privacy/security, veri hakkı ya da güvenilmeyen teslimat nedeniyle yayın öncesi kapatılması gereken risk |
| P2 | Yakın vadede kapatılması gereken önemli doğruluk, erişilebilirlik, performans, test veya sözleşme borcu |
| P3 | Daha düşük etkili dayanıklılık, sürdürülebilirlik ve geliştirici deneyimi iyileştirmesi |

Severity, yalnız exploit ihtimalini değil finansal üründeki kullanıcı güvenini,
yanlış karar riskini, geri döndürülebilirliği ve quality gate'in hatayı yakalama
olasılığını birlikte değerlendirir. Alt rapor severity'leri korunmuştur; ana
yol haritası ise birbirini büyüten P1'leri de release gate olarak ele alır.

## Tekilleştirilmiş kritik bulgu haritası

### 1. Legal, privacy ve veri envanteri — yayın engeli

- Shipped TR/EN privacy dosyaları açıkça template/legal review gerektirdiğini,
  KVKK kaynağı ise veri sorumlusu/adres/KEP alanlarının doldurulması gerektiğini
  söyler.
- Metin “sunucuda kullanıcıya özel veri yok”, saved scenarios yerel ve device
  UUID anonim gibi iddialar taşırken uygulama persistent `X-Device-ID` ile
  finansal payload ve kaydedilmiş senaryoları backend'e yollar.
- “Uninstall tüm local veriyi siler” ifadesi iOS Keychain yaşam döngüsü için
  garanti edilemez. Sentry 90 günlük retention da repo içinden doğrulanmamıştır.
- `CLAUDE.md` `/v1/account/data-export` akışını var kabul eder; endpoint/UI/test
  implementasyonu bulunmamıştır.

**Kaynak:** Ürün P0 legal; SEC-04, SEC-11; QE bağımsız doğrulama tablosu.
**Çıkış kanıtı:** Hukuk/DPO onaylı versioned TR kaynak + doğrulanmış EN çeviri,
gerçek data inventory/retention/deletion/export matrisi, store privacy
formlarıyla sign-off ve metin–network/storage sözleşme testi.

### 2. Release governance ve production isolation — yayın engeli

- 2026-08-18 GitHub API anlık görüntüsünde `main` protection 404, rulesets `[]`,
  environments `[]`, release workflow geçmişi `[]` idi.
- Workflow'da `environment: production` yazmak tek başına required reviewer
  yaratmaz; environment koruması GitHub ayarında ayrıca tanımlanmalıdır.
- Release guard tag'in yalnız `main` atası olmasını denetler. Tag SHA için CI,
  test, analyzer, coverage, platform build veya `main` HEAD eşitliği aramaz;
  lightweight tag fallback'i de kabul eder.
- Staging ve production repository variable'ları aynı geçici ngrok origin'idir.
  Production hostname allowlist/preflight yoktur.
- Secret-bearing signing/store job'ları mutable action tag'leri çalıştırır;
  repository action policy `allowed_actions=all`, SHA pinning kapalıdır.

**Kaynak:** SEC-01, SEC-02, SEC-07–09, SEC-16; QE-01, QE-06.
**Çıkış kanıtı:** Protected `main` ruleset + required exact checks, önceden
tanımlı/reviewer-protected production environment, farklı sahipliği doğrulanmış
staging/production origin'leri, exact-SHA CI gate, immutable action SHA'ları ve
store'a yazmayan başarılı RC dry-run.

### 3. Marka ve store asset'leri — yayın engeli

- iOS AppIcon 1024px ve Android launcher seti görsel olarak varsayılan Flutter
  logosudur; boş/şeffaf iOS launch asset'i de bitmiş marka deneyimi sunmaz.

**Kaynak:** Ürün P0 marka/asset; QE bağımsız görsel doğrulama.
**Çıkış kanıtı:** Marka onaylı iOS AppIcon ve Android adaptive icon tüm
density/appearance varyantlarında; launcher, launch screen, store listing ve
gerçek cihaz/simulator screenshot QA.

### 4. Finansal sonuç bütünlüğü — yayın engeli

- Portföyde bazı backend hesapları başarısız olduğunda eksik alt küme toplamı
  uyarısız biçimde tam portföy sonucu diye gösterilebilir, kaydedilebilir ve
  paylaşılabilir.
- Portföy async cevabı sonradan değişmiş form state'i ile etiketlenebilir; eski
  istek yeni sonucu ezebilir. What-if/DCA'da form değişince eski sonuç ve
  save/share aksiyonları geçerli kalabilir.
- Dil değişimi finansal hesapları yeniden çağırır; portföyde kalem sayısı kadar
  kota tüketebilir ve sonuçları sessizce silebilir.
- DCA date picker Cancel, comparison tarih kesişimi ve ayrık nullable inflation
  payload'ı üç ayrı crash yolu üretir.
- Para input/request sözleşmelerinde kanonik `Decimal` kuralına rağmen `num`
  kullanımı sürer; tarih/replay/API bozuk-2xx invariant'ları akışlar arasında
  tutarsızdır.

**Kaynak:** FIN-01–FIN-15, özellikle FIN-01–07.
**Çıkış kanıtı:** Immutable request/result snapshot, stale response rejection,
explicit complete/partial/dirty state, Decimal round-trip ve bütün P1'ler için
deterministik BLoC/widget/contract regresyon testleri.

### 5. Account deletion ve veri sahibi hakkı — yayın engeli

- Backend DELETE false/exception dönse de local wipe secure storage'ı ve eski
  device identity'yi siler. Server kaydı device ID ile ilişkiliyse kullanıcı
  eski kaydı hedefleyen retry kabiliyetini yitirebilir.
- Bu davranış `CLAUDE.md`deki “backend 200 olmadan cleanup yok” sözleşmesine,
  state/repository yorumlarına ve kullanıcı beklentisine aykırıdır.

**Kaynak:** SEC-03; ürün account deletion P2.
**Çıkış kanıtı:** Idempotent deletion request ID/proof, lost-response ve retry
state'i, server accepted/completed doğrulaması, device identity'nin erken
silinmediğini kanıtlayan backend contract + integration test ve dürüst UI
durumları.

### 6. Observability ve PII sınırı — yayın engeli

- Sentry scrub regex'i `amount=99`, `price=0.5` gibi küçük değerleri korur;
  typed context nesneleri ve message template için deny-by-default temizlik yok.
- Store release komutları `SENTRY_DSN` geçmez; dSYM/R8 mapping upload ve canary
  doğrulaması yoktur. Rollout dokümanı crash-free metriğine dayanırken release
  binary bu metriği üretmeye hazır değildir.

**Kaynak:** SEC-05, SEC-06, SEC-12.
**Çıkış kanıtı:** Serialized Sentry envelope privacy snapshot'ı, structured
data allowlist'i, environment-scoped DSN, exact release symbol/mapping upload,
sembollenen canary ve privacy-safe production-like RC dashboard'u.

### 7. App config, legal onboarding ve destructive UX — yayın engeli

- App config default state ile sayfalar birlikte oluşturulur; scenarios ilk
  istekte yanlış planı gönderebilir, diğer finansal sayfalar flag/limitleri
  reaktif dinlemez.
- Onboarding'de Atla, kullanıcı legal bağlantıları görmeden kabul sürümü yazar;
  saklanan sürüm hiçbir yerde current sürümle karşılaştırılmaz.
- Senaryo silme yalnız swipe ile ve confirm/undo/erişilebilir eşdeğer olmadan
  yapılır. Onboarding/delete-account scroll olmayan layout'ları büyük text
  scale/küçük ekran/klavye durumunda akışı bloke edebilir.

**Kaynak:** Ürün P1 bulguları; QE bağımsız P0/P1 doğrulama tablosu.
**Çıkış kanıtı:** Config ready/fallback state ve cold-start tests; görünür,
versioned legal acknowledgement; accessible confirm/undo; 320dp, 200% text
scale, keyboard, screen reader ve reduced-motion widget/device matrisi.

### 8. Quality gate ve agent tooling — release sonrası değil, düzeltmelerle paralel

- Current line coverage `%46,04 (1527/3316)`; generated l10n çıkarılsa da
  `%52,09 (1408/2703)`, belgelenmiş `%60+` baseline'ın altındadır. Workflow
  threshold uygulamaz, Codecov upload fail-closed değildir.
- Yalnız 5 `testWidgets`, 0 integration ve 0 golden testi vardır; 9 page/root
  bootstrap ve ana kullanıcı yolculukları test edilmez.
- Master-review skill'inin zorunlu planı yoktur ve parent dizini ignore edilir.
- Dört agent/skill para için `num` tavsiye eder; scaffold'lar projede olmayan
  `Result`, `FailureOrSuccess` ve `.localized` API'leri üreterek derlenmeyen ya
  da ikinci bir hata mimarisi doğuran kod yazdırabilir.
- CI `gen-l10n` sonrası committed generated dosyalarda dirty diff aramaz;
  YAML/workflow/shell/Markdown/skill sözleşmeleri için deterministik gate yoktur.

**Kaynak:** QE-01–10; FIN-21; ürün semantics/test bulgusu.
**Çıkış kanıtı:** Normalize edilmiş ve fail-closed project/patch coverage,
risk-bazlı widget/integration/golden matrisi, tracked review planı, gerçek proje
API'lerine uyan scaffold fixture eval'leri, generated dirty-diff ve non-Dart CI
kontrolleri.

## Önceliklendirilmiş uygulama programı

| Dalga | Amaç | Dahil işler | Tamamlanma kanıtı |
|---|---|---|---|
| 0 — Release freeze | Yanlış ortama/onaysız veya hukuken hazır olmayan build gitmesini engelle | Legal sign-off/data map, prod/staging origin ayrımı, GitHub ruleset/environment, exact-SHA CI gate, immutable Actions, özgün ikonlar | Store'a yazmayan RC; GitHub API/config çıktısı; hukuk/marka sign-off |
| 1 — Finansal güven | Yanlış/eksik/stale finansal sonucun gösterilmesini, kaydedilmesini ve paylaşılmasını durdur | FIN-01–07 önce; snapshot/completeness/dirty modeli, crash fix'leri, Decimal input/request | Her P1 için önce kırmızı sonra yeşil deterministik test; partial/stale sonuç kabul testi |
| 2 — Privacy ve veri yaşam döngüsü | Silme, export, identity ve telemetry sözleşmesini gerçek hale getir | Account deletion protocol, export kararı, Sentry scrub/DSN/symbols, retention doğrulaması | Backend+client contract/integration tests; scrubbed envelope; deletion lost-response testi |
| 3 — Temel ürün deneyimi | Cold-start, onboarding, destructive action ve erişilebilirlik blokajlarını kapat | Config-ready model, versioned legal UX, scenario undo/confirm, responsive/semantic/dark-mode | TR/EN, light/dark, 320dp/200%, keyboard ve screen-reader matrisi |
| 4 — Kalıcı kalite sistemi | Aynı sınıf hataların tekrar girmesini önle | Coverage gate, integration/golden smoke, l10n diff, actionlint/shellcheck/link/path checks, skill fixtures | Protected required checks; failing fixture örnekleri; `%60+`a kontrollü yükseliş planı |
| 5 — Hardening ve bakım | P2/P3 güvenilirlik/perf/doc borcunu kapat | Error mapping, asset cache, retry/cancel, date helpers, release provenance/idempotency, docs single-source | Chaos/failure tests, SBOM/checksum/attestation, güncel runbook ve ADR'ler |

Dalga 0 ve 1 paralel yürütülebilir; ancak ikisi ve Dalga 2'nin silme/privacy
acceptance kriterleri tamamlanmadan production onayı verilmemelidir. Her fix
PR'ında ilgili rapor ID'si, regresyon testi ve kullanıcıya etkisi yer almalıdır.

## Doğrulanmış güçlü kontroller

- Finansal domain katmanlarında Flutter/Dio/IO import ihlali, presentation'da
  HTTP/Dio bağımlılığı veya presentation→data import'u bulunmadı.
- Sonuç entity/model'lerinde para ve birimler büyük ölçüde `Decimal` ve
  `MoneyParser.requireDecimal` kullanır; exact `0.1 + 0.2 == 0.3` portföy testi
  vardır. Problem input/request boundary'sindeki sapmadır.
- Typed `AppError` omurgası ve Dio mapping'i genel olarak tutarlıdır; bulgular
  2xx/403/404 ve portfolio outcome gibi sınırlı sapmaları gösterir.
- TR/EN ARB dosyaları JSON olarak geçerli, key setleri **238/238** ve
  placeholder şemaları eşittir; güncel generated l10n commit'i de tutarlıdır.
- Güncel main CI format, fatal analyzer ve **379 testi** geçirir. İnceleme bu
  testlerin başarısız olduğunu değil kapsam/gate'in yetersizliğini söyler.
- 116 hosted Pub dependency OSV anlık sorgusunda bilinen eşleşme çıkmadı;
  tracked private key/token veya signing artifact bulunmadı.
- Android production cleartext kapalı, backup/device-transfer exclude-all,
  manifest izinleri minimaldir. Retry varsayılanı yalnız GET/HEAD için çalışır.
- iOS fotoğraf izni add-only ve lokalize; keychain sync/device-transfer sınırı
  daraltılmıştır. Bu, uninstall garantisi anlamına gelmez.
- XML/plist/strings/YAML parse, shell syntax, Gradle wrapper ZIP bütünlüğü ve
  Git object bütünlüğü kontrolleri başarılıdır.
- Gradle distribution SHA-256 ile pinlidir; Android release minify/resource
  shrink ve iOS dSYM/manual signing temeli mevcuttur.

## Test ve doğrulama gerçekliği

| Kontrol | Sonuç | Yorum |
|---|---|---|
| Güncel exact-commit GitHub CI | Başarılı | [Run 32134705408](https://github.com/cemililik/Saydin.Client/actions/runs/32134705408): format/analyze/test yeşil |
| Test sayısı | 379 başarılı | 318 `test`, 43 `blocTest`, 5 `testWidgets` deklarasyonu; suite toplamı CI logundan |
| Coverage | `%46,04` raw; `%52,09` generated l10n hariç | `%60+` sözleşmesi sağlanmıyor ve gate yok |
| Android/iOS build | Son main push'ta skipped | Workflow koşulu; son PR build başarısı release artifact smoke yerine geçmez |
| Release workflow | Hiç run yok | Store path, approval ve retry davranışı kanıtlanmamış |
| L10n | 238/238, şema temiz | Generated dirty-tree gate eksik |
| OSV | 116/116 sorgu, 0 eşleşme | 2026-08-18 anlık görüntüsü; scheduled/fail-closed değil |
| Yerel Flutter/Dart | Kullanılamadı | Audit ortamında PATH'te yok; proje test failure'ı olarak yorumlanmadı |

## Sınırlar ve belirsizlikler

- Bu review statik kaynak/sözleşme analizi, mevcut CI/Codecov kanıtı, dosya
  bütünlük kontrolleri ve GitHub yapılandırma anlık görüntüsünü birleştirir.
  Yerel Flutter SDK olmadığı için cihaz/simulator, screen reader, golden,
  performance profile, network fault injection ve penetration testi yapılmadı.
- Backend kodu ve production altyapısı bu repository kapsamında değildir.
  Device-ID ile orphan record, retention ve backend deletion davranışı güçlü
  client-side kanıta dayalı inference olarak işaretlenmiştir; backend contract
  testiyle doğrulanmalıdır.
- Sentry/store dashboard ve hukuk onay kayıtlarına erişim yoktur. Hukuki ihlal
  hükmü verilmemiş; shipped kaynakların açık template işareti ve teknik veri
  akışı uyumsuzluğu release sign-off riski olarak değerlendirilmiştir.
- GitHub branch/environment/variable durumu 2026-08-18 anlık görüntüsüdür ve
  dış ayarlar değiştirildiğinde yeniden kontrol edilmelidir.
- Responsive overflow gibi bazı bulgular runtime screenshot ile üretilmiş
  kesin crash değil, kod yapısı + test yokluğu üzerinden yüksek güvenli
  failure-mode riskidir. Finansal null dereference ve date-picker yolları ise
  doğrudan kod akışından deterministik görünmektedir.
- Build/cache/editor çıktıları tracked proje girdisi değildir. 303 tracked
  dosyanın tamamı [kapsam manifestosunda](05-review-coverage-manifest.md)
  kayıtlıdır.

## Production readiness kabul listesi

Production/store kararı aşağıdaki kanıtların tamamı mevcut olmadan
**NO-GO** kalmalıdır:

- [ ] Hukuk/DPO ve marka sign-off; template yorum/placeholder'lar kapanmış,
      privacy/KVKK metni gerçek data inventory ile eşleşiyor.
- [ ] Farklı, sahipliği doğrulanmış production/staging origin'leri ve build-time
      production host allowlist/preflight.
- [ ] Protected `main`, required exact checks ve bağımsız reviewer-protected
      production environment GitHub API'de görünür.
- [ ] Tag SHA'nın analyze/test/coverage/platform release smoke başarısı release
      workflow'da fail-closed doğrulanır; lightweight tag reddedilir.
- [ ] Finansal P1'lerin tamamı immutable snapshot/partial/dirty semantiğiyle ve
      deterministik regresyon testleriyle kapanır.
- [ ] Account deletion timeout/lost-response/retry halinde server sonucunu ve
      kullanıcı retry hakkını korur; device identity erken silinmez.
- [ ] Production-like RC'de Sentry canary sembollenir ve serialized envelope'da
      device/finansal PII bulunmaz.
- [ ] Config cold-start, legal version/skip, scenario delete/undo ve 200% text
      scale ana yolculuk testleri geçer.
- [ ] Coverage denominator'ı tanımlıdır, mevcut baseline fail-closed gate edilir
      ve `%60+` için düşüşe izin vermeyen yükseliş planı aktiftir.
- [ ] İmzalı AAB/IPA store'a yazmadan boot/API smoke'tan geçer; checksum,
      source SHA, lock hash ve SBOM/provenance yayımlanır.

## Sonuç

Projenin temeli düzeltilebilir ve birçok doğru mühendislik tercihi içerir;
ancak mevcut yeşil CI sinyali, kullanıcıya doğru finansal sonuç, gerçek legal
disclosure veya güvenli production teslimatı garanti etmiyor. En doğru sıra,
önce yayın zincirini ve legal/ortam sınırını fail-closed hale getirmek; aynı
anda finansal P1'leri regression-first kapatmak; ardından privacy/account
deletion ve temel kullanıcı yolculuklarını bütünleşik testlerle güvenceye
almaktır. Bu rapor uygulama değişikliği yapmaz; uygulanabilir düzeltme backlog'u
ve doğrulanabilir release kabul sözleşmesi sunar.
