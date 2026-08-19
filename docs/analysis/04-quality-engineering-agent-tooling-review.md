# Saydın.Client — Quality Engineering, Agent Tooling ve Otomasyon Review

**Tarih:** 2026-08-18
**İncelenen commit:** `441eda4b5209f7814345eede1cb64438174ca6f2` (`main`)
**Review türü:** Salt-okunur kod/doküman incelemesi; uygulama kodu değiştirilmedi
**Kapsam:** `.claude/**`, test ağacının bütünü, repo-geneli test stratejisi,
`analysis_options.yaml`, l10n üretim kapıları, README/CLAUDE/docs ve otomasyon
tutarlılığı, `.coderabbit.yaml`, `.sourcery.yaml`, `.githooks/**`, `.gitignore`,
root metadata, CI/Codecov ve `03-product-ux-accessibility-docs-review.md`
iddialarının bağımsız doğrulaması.

## Yönetici özeti

Repo, birim/BLoC/repository testi açısından küçümsenmeyecek bir tabana sahip:
güncel `main` CI koşusunda **379 test**, format ve `flutter analyze
--fatal-infos` başarılıdır. Bununla birlikte bu yeşil sonuç bugün kalite
sözleşmesini uygulayan bir release kapısı değildir. Aynı koşunun gerçek line
coverage değeri **%46,04 (1527/3316)**; üretilmiş l10n dosyaları çıkartıldığında
bile **%52,09 (1408/2703)** ile belgelenmiş `%60+` baseline'ın altındadır.
Workflow yalnız oranı özetler, eşik uygulamaz; Codecov hataları CI'ı düşürmez ve
`main` için branch protection/ruleset yoktur.

Daha kritik olarak tag-driven release workflow'u tag'in yalnız `main` atası
olduğunu doğruluyor; o SHA için CI/test/analyze/coverage başarısını doğrulamadan
Android ve iOS mağaza job'larına ilerliyor. Agent/tooling katmanında da aynı
“sözleşme var, çalışabilir kapı yok” örüntüsü bulunuyor: master-review
launcher'ın zorunlu planı repoda yok ve onu taşıması gereken dizin ignore
ediliyor; dört agent/skill para için `num` önererek kanonik `Decimal`
sözleşmesiyle çelişiyor; scaffold şablonları projede hiç tanımlı olmayan
`Result`/`FailureOrSuccess` API'leri ve yanlış hata lokalizasyon çağrısı üretiyor.

Yeni bulgu toplamı **10**: **P0 0, P1 7, P2 3, P3 0**. Önceki 03 raporundan
bağımsız olarak doğrulanan **2 P0 + 5 P1** ürün bulgusu ve dokümantasyon/
CodeRabbit bulgusu bu sayıya tekrar eklenmemiştir; ayrı doğrulama tablosunda
çapraz referanslanmıştır.

## Yöntem ve sınırlar

- `.claude/agents` ve `.claude/skills` altındaki **10 dosyanın tamamı** satır
  bazında okundu.
- `test/**` altındaki **44 Dart test dosyasının tamamı** envanterlendi; test
  hedefleri 155 `lib/**/*.dart` dosyası, 9 page, 10 BLoC/Cubit, 9 use case ve
  11 repository implementasyonuyla karşılaştırıldı.
- Statik sayım: **318** doğrudan `test(...)`, **43** `blocTest`, **5**
  `testWidgets`; **0** integration test ve **0** golden assertion.
- Yerel değerlendirme ortamında `flutter` ve `dart` bulunmuyor. Bu nedenle
  yerelde başarısız test sonucu iddia edilmedi. Bunun yerine aynı commit'in
  2026-08-18 tarihli [GitHub Actions koşusu](https://github.com/cemililik/Saydin.Client/actions/runs/32134705408)
  ve [Codecov commit raporu](https://app.codecov.io/gh/cemililik/Saydin.Client/commit/441eda4b5209f7814345eede1cb64438174ca6f2)
  salt-okunur olarak doğrulandı.
- GitHub REST kontrollerinde `main` için klasik branch protection **404 / not
  protected**, repository ruleset listesi ise boş döndü. Bu, Codecov uploader
  logundaki “branch is protected” uyarısından daha doğrudan repo-yetkili
  kanıttır.
- Bulgular çalıştırılabilirlik, doğruluk, finansal precision, release güvenliği,
  test piramidi, sürdürülebilirlik ve geliştirici deneyimi lenslerinden
  değerlendirildi. Salt stil tercihi finding yapılmadı.

## Öncelik modeli

- **P0:** Yayını derhal durduracak doğrulanmış güvenlik/hukuk/veri kaybı veya
  geniş kullanıcı kitlesine kesin yanlış finansal sonuç.
- **P1:** Release veya ana geliştirme akışını güvenilmez kılan, yanlış kod
  üreten ya da kritik regresyonu yeşil CI ile geçirebilen yüksek risk.
- **P2:** Belirli tetikleyicide kalite/regresyon riski oluşturan fakat doğrudan
  kaçış yolu veya insan kontrolü bulunan eksik kapı/tutarsızlık.
- **P3:** Düşük etkili bakım, açıklık veya ergonomi sorunu.

## Bulgular

### QE-01 — P1 — Release workflow, release edilen SHA'nın CI başarısını doğrulamıyor

**Konum:** `.github/workflows/release.yml:49-95`,
`.github/workflows/release.yml:214-244`,
`.github/workflows/release.yml:367-398`, `.claude/skills/release/SKILL.md:6-8`

**Kanıt:** `guard` job'u sadece tag formatını ve tag commit'inin `main` atası
olmasını kontrol ediyor. Android ve iOS release job'ları `needs: [guard,
detect-channel]` ile doğrudan başlıyor; workflow'un hiçbir yerinde `flutter
analyze`, `flutter test`, coverage eşiği, ilgili commit check-suite sonucu veya
başarılı CI workflow bağımlılığı yok. Buna karşın release skill'i `main` yeşil
değilse release'i iptal etmeyi söylüyor ve “guard job zaten engelleyecek”
iddiasında bulunuyor; mevcut guard bunu yapmıyor. GitHub API ayrıca `main` için
branch protection ve ruleset olmadığını gösterdi.

**Etki:** CI'ı kıran bir commit `main`e doğrudan push edilebilir veya CI devam
ederken tag'lenebilir. Tag ancestry kontrolünü geçtiği için signed AAB/IPA
üretilip RC kanalına otomatik, production kanalına insan approval'ından sonra
yüklenebilir. Approval test sonucunun makinece doğrulandığı anlamına gelmez.

**Tetikleme:** `main`e test/analyzer hatalı commit push et; hemen `vX.Y.Z-rc.N`
tag'i oluştur. Tag `main` atasıdır, guard yeşil olur ve staging release job'ları
CI sonucunu beklemeden ilerler.

**Önerilen fix:** Test/analyze/coverage'ı `workflow_call` ile reusable bir
quality workflow'a taşıyıp release'in ilk zorunlu job'u yapın veya tag SHA için
GitHub Checks API'den beklenen check setinin tamamını ve conclusion=`success`
durumunu fail-closed doğrulayın. Android/iOS job'ları bu quality job'una `needs`
vermeden başlamamalı. `main`e required status checks + PR zorunluluğu uygulayan
branch ruleset ekleyin. Release skill'indeki “guard engeller” cümlesini gerçek
mekanizmayla eşleyin.

**False-positive değerlendirmesi:** Production environment approval riski
azaltır ama RC/staging için garanti değildir ve production onaylayıcısına test
kanıtı zorunlu kılmaz. Release build'in derlenmesi de birim/widget testleri ve
analyzer yerine geçmez. Bulgu geçerlidir.

### QE-02 — P1 — `%60+` coverage sözleşmesi karşılanmıyor ve hiçbir yerde gate edilmiyor

**Konum:** `CLAUDE.md:125-133`, `.github/workflows/ci.yml:91-129`,
`.githooks/pre-commit:50-57`

**Kanıt:** CLAUDE `%60+` baseline ve PR'da düşürmeme hedefi tanımlıyor. Güncel
`main` koşusunun kendi lcov özeti **%46,0 (1527/3316)**, Codecov kesin değeri
**%46,04**. Codecov dosya dökümünden üç `app_localizations*.dart` çıktısı
çıkarıldığında oran **%52,09 (1408/2703)**; dolayısıyla sonuç yalnız generated
code'un denominator'ı şişirmesiyle açıklanamıyor. CI oranı sadece Step Summary'ye
yazıyor; threshold karşılaştırması yok. Coverage dosyası yoksa adım `exit 0`,
Codecov upload `fail_ci_if_error: false`. Repoda `.codecov.yml` yok ve son
commit'in GitHub status setinde yalnız `codecov/patch` var; project coverage
gate'i yok. Pre-commit test komutu da `--coverage` çalıştırmıyor.

**Etki:** Coverage `%60`ın altında kalırken veya daha da düşerken CI yeşil
olabilir. “379 test geçti” sayısı geniş bir test yüzeyi izlenimi verir fakat
satırların çoğu ve lcov'a hiç girmeyen kaynak dosyaları hakkında merge kararı
vermez. Belgelenmiş kalite SLO'su bugün ölçüm notudur, sözleşme değildir.

**Tetikleme:** Test edilmeyen bir production branch'i ekle ya da mevcut testli
satırları testsiz kodla genişlet. `flutter test --coverage` başarılı olduğu
sürece coverage özet adımı oran ne olursa olsun 0 döner ve upload hatası da CI'ı
düşürmez.

**Önerilen fix:** Önce denominator politikasını açıkça belirleyin: generated
l10n'i hariç tutun, fakat test sırasında import edilmemiş bütün production
dosyalarını lcov'a dahil edin. CI'da project threshold'u başlangıçta mevcut
normalize baseline'a eşitleyip kontrollü biçimde `%60+`a yükseltin; aynı anda
patch coverage ve “project düşmesin” kapısı uygulayın. Coverage üretilemezse
fail-closed olun, Codecov config ve upload failure'ını gerekli check yapın.

**False-positive değerlendirmesi:** Generated l10n'i çıkarmak oranı yükseltiyor,
ancak yalnız **%52,09**a; sözleşme yine karşılanmıyor. Ayrıca Codecov yalnız 93
dosya raporluyor, repo 155 lib Dart dosyası içeriyor; bu nedenle `%46,04` tüm
kaynakların konservatif “gerçek coverage”ı olarak dahi okunmamalıdır. Bulgu
robusttur.

### QE-03 — P1 — Master-review launcher temiz clone'da başlatılamıyor

**Konum:** `.claude/skills/master-review/SKILL.md:3-8`,
`.claude/skills/master-review/SKILL.md:47-64`, `.gitignore:51-53`

**Kanıt:** Launcher `docs/code-reviews/master/MASTER-REVIEW-PLAN.md` dosyasını
zorunlu prerequisite ilan ediyor, önce `cat`, sonra session'a `cp` ediyor ve
plansız dispatch'i yasaklıyor. Bu dosya mevcut checkout'ta yok. Daha önemlisi
tüm `docs/code-reviews/` dizini `.gitignore` altında; `git check-ignore` zorunlu
plan yolunu doğrudan bu kuralla eşledi. `git ls-files` planı göstermiyor.

**Etki:** “master review / proje genelinde review” tetikleyicisi en başta eksik
dosyada durur; 24 lot, 6 cross-cutting, verification ve consolidation
brief'lerinin hiçbiri launcher içinde bulunmadığından güvenli fallback de yoktur.
Bir geliştiricinin makinesinde tesadüfen bulunan untracked plan, ekip genelinde
tekrarlanabilirlik sağlamaz.

**Tetikleme:** Temiz clone'da master-review skill'ini başlat; 1. adımdaki `cat`
“No such file” verir. Planı normal yolla bu dizine eklemek de ignore nedeniyle
review/commit envanterine girmez.

**Önerilen fix:** Kanonik planı tracked bir yola (ör.
`docs/review/MASTER-REVIEW-PLAN.md`) taşıyın veya `.gitignore`da yalnız session
çıktılarını ignore edip planı `!docs/code-reviews/master/MASTER-REVIEW-PLAN.md`
ile açıkça unignore edin. Skill başlangıcına dosya-varlık, şema/version ve lot
sayısı preflight'ı ekleyin; eksikse ajan dispatch etmeden tek, eyleme dönük hata
verin. Sabit model adı ve `TodoWrite` gibi runtime-spesifik isimleri capability
kontrolüyle yönetin.

**False-positive değerlendirmesi:** Ignore edilmiş plan yerel başka bir
makinede bulunabilir; fakat launcher repo-bazlı bir ekip aracı olarak temiz
clone'da çalışmalıdır. Local artifact olasılığı bulguyu geçersiz kılmaz.

### QE-04 — P1 — Dört agent/skill `Decimal` yerine `num` üretiyor veya öneriyor

**Konum:** `.claude/agents/saydin-reviewer.md:45-50`,
`.claude/agents/saydin-reviewer.md:106-110`,
`.claude/skills/develop-task/SKILL.md:47-51`,
`.claude/skills/feature-scaffold/SKILL.md:38-43`,
`.claude/skills/yasak-check/SKILL.md:62-67`; kanonik sözleşme:
`CLAUDE.md:39-46`, `CLAUDE.md:156-171`, `CLAUDE.md:495-501`

**Kanıt:** Kanonik kural para alanlarında `double/float/num` yasaklayıp
`Decimal` + `MoneyParser.requireDecimal` istiyor. Buna karşı reviewer dahili
hesapta `num`un “yeterli precision” verdiğini söylüyor ve finding fix'i olarak
`final num price` öneriyor. `develop-task`, `feature-scaffold` ve `yasak-check`
aynı eski `num/String parse` sözleşmesini tekrar ediyor. `decimal` dependency'si
de `pubspec.yaml:39-41`de bu risk için eklenmiş.

**Etki:** Agent-generated yeni finansal entity/repository kodu IEEE-754
precision riskini geri getirir. Daha kötüsü, proje-bilgili reviewer bu regresyonu
bulmak yerine “fix” olarak önerebilir; aynı diff farklı araçlarda hem doğru hem
yasak sayılır.

**Tetikleme:** `feature-scaffold` ile tutar alanı olan feature oluştur veya
reviewer'a `double price` ver. Şablon/reviewer `num`a geçmeyi başarılı çözüm
olarak sunar; CLAUDE ve mevcut Decimal mimarisi ihlal edilir.

**Önerilen fix:** Para tip politikasını tek makine-okunur referansa taşıyın ve
tüm skill'ler ona link versin. Tüm örnekleri `Decimal`, JSON boundary'de
`MoneyParser.requireDecimal`, yalnız display boundary'de `.toDouble()` olarak
değiştirin. Agent fixture/eval ekleyin: `double amount`, `num price` ve string
money payload vakalarında beklenen review sonucu aynı olmalı.

**False-positive değerlendirmesi:** Yüzde/oran alanlarında `double` serbesttir;
bulgu bu alanları kapsamıyor. İtiraz yalnız açıkça `amount/price/total/value`
para alanlarına verilen `num` tavsiyesidir.

### QE-05 — P1 — Scaffold şablonları projede olmayan hata/result API'leriyle derlenmeyen kod üretiyor

**Konum:** `.claude/skills/feature-scaffold/SKILL.md:40-44`,
`.claude/skills/feature-scaffold/SKILL.md:77-90`,
`.claude/skills/bloc-page/SKILL.md:47-58`,
`.claude/skills/bloc-page/SKILL.md:109-130`,
`.claude/skills/bloc-page/SKILL.md:150-183`,
`.claude/skills/bloc-page/SKILL.md:206-211`

**Kanıt:** Tüm `lib`, `test`, `pubspec.yaml` taramasında `Result` veya
`FailureOrSuccess` tanımı/kullanımı yok. Gerçek domain repository/use case
sözleşmeleri `Future<T>` döndürüyor ve `AppError` fırlatıyor. Buna rağmen
feature scaffold aynı interface için bir satırda `Future<Result<Entity,
AppError>>`, iki satır sonra `FailureOrSuccess<T>`, testte `Result.ok` üretiyor.
Bloc-page `Result.ok/err` kullanıyor; hata mesajında mevcut
`localizedMessage(context.l10n)` yerine tanımsız `localized(context)` çağırıyor.
Ayrıca page iskeleti `sl<PortfolioSummaryBloc>()` kullanırken aynı skill bunu
widget içinde yasaklıyor.

**Etki:** Skill'in “tam feature/page + test” çıktısı analyzer'dan geçemez veya
agent eksik soyutlamaları kendi başına icat ederek projede ikinci bir hata
modeli kurar. Kullanıcı iskelet üretiminden sonra mimari karar vermek ve geniş
fix turu yapmak zorunda kalır; skill'in temel değer önerisi tersine döner.

**Tetikleme:** `feature-scaffold` veya `bloc-page` örneğini imports dahil
uygula; `Result`, `FailureOrSuccess` ve `.localized` unresolved olur.

**Önerilen fix:** Tek hata sözleşmesi seçin. Mevcut proje korunacaksa şablonları
`Future<T>` + `on AppError catch` ve `localizedMessage(context.l10n)` ile gerçek
koddan türetin. Result tipi isteniyorsa önce ADR, dependency/implementation ve
tek generic sırası oluşturulmalı; sonra bütün repo migrate edilmelidir. Her
skill için temporary fixture'a scaffold edip `flutter analyze` ve hedef testi
çalıştıran smoke eval ekleyin. `sl()` kuralının “provider create içinde serbest,
descendant build içinde yasak” gibi gerçek niyetini açık yazın.

**False-positive değerlendirmesi:** Bu isimler başka bir global Claude
runtime'ından gelmiyor; üretilen Dart projesinde import/tanım gerekir. Repo
tarama sonucu sıfırdır. Bulgu geçerlidir.

### QE-06 — P1 — Device deploy skill değişken ngrok endpoint'ini kalıcı ve varsayılan komut olarak gömüyor

**Konum:** `.claude/skills/device-deploy/SKILL.md:8-20`,
`.claude/skills/device-deploy/SKILL.md:34-46`,
`.claude/skills/device-deploy/SKILL.md:51-63`; karşı sözleşme:
`CLAUDE.md:426-433`, `CLAUDE.md:460-477`

**Kanıt:** Skill `https://fumed-cleverishly-moses.ngrok-free.dev/` adresini
“aktif backend” sabiti ve hem debug hem release komutunun varsayılanı yapıyor;
sonra URL'nin süresinin dolabileceğini kabul ediyor. CLAUDE ise aktif dev
tünelinin değişken olduğunu, committed dosyada listelenmemesini ve güncel
değerin takım kanalından alınmasını açıkça söylüyor.

**Etki:** Süresi dolan endpoint deploy'u bozar; daha riskli olarak yeniden
tahsis edilmiş veya artık yanlış ortama bakan bir tünel test cihazını beklenmeyen
backend'e bağlar. Finansal test girdileri yanlış ortama gönderilebilir ve
“cihazda çalıştı” doğrulaması güvenilmez olur.

**Tetikleme:** Kullanıcı URL belirtmeden “iPhone'a gönder” der; skill “genelde
aynı kalır” varsayımıyla committed ngrok URL'sini komuta koyar.

**Önerilen fix:** URL'yi skill'den kaldırın. Deploy öncesi zorunlu, fail-closed
bir kaynak kullanın: secret manager/CI environment, ignore edilen yerel env
dosyası veya kullanıcıdan o oturum için açık endpoint. Host allowlist,
`/health` ve environment identity yanıtını doğrulamadan deploy etmeyin; release
mode'da geçici tüneli ayrıca yasaklayın. Device ID kişisel secret değildir fakat
env/config üzerinden yönetmek cihaz değişimini kolaylaştırır.

**False-positive değerlendirmesi:** Skill URL'yi sormayı “opsiyonel” bırakıyor;
bu bir mitigasyondur. Ancak önerilen default hâlâ hardcoded değerdir ve kullanıcı
cevap vermediğinde doğrudan çalıştırılır; çelişki sürer.

### QE-07 — P1 — Test piramidi kritik kullanıcı yolculuklarını ve platform entegrasyonunu sınamıyor

**Konum:** `.github/workflows/ci.yml:91-92`, `pubspec.yaml:54-60`,
`lib/main.dart:14-109`, `lib/app.dart:49-130`,
`test/features/what_if/presentation/widgets/amount_input_test.dart:23-47`,
`test/features/what_if/presentation/widgets/result_card_test.dart:47-66`

**Kanıt:** Repo 9 page ve uygulama başlangıcı/DI/navigation kabuğu içeriyor,
fakat yalnız 5 `testWidgets` iki What-if widget'ına ait. Hiçbir page, `SaydinApp`,
`AppHome`, `MainShell`, `main()` veya `configureDependencies()` widget/smoke
testine sahip değil. `integration_test/` ağacı ve `matchesGoldenFile` kullanımı
yok; `pubspec`te integration test dependency/config de yok. CI yalnız standart
`flutter test --coverage` çalıştırıyor. Böylece gerçek app bootstrap, route
geçişi, secure/shared storage, locale/theme değişimi, config cold start ve iki
platform build sonrası davranış birlikte test edilmiyor.

**Etki:** Repository ve BLoC state testleri yeşilken onboarding → hesaplama →
senaryo kaydet/sil, legal kabul/sürüm, hesap silme/reset, locale/theme restart ve
paywall/config yarışları kullanıcı seviyesinde kırılabilir. Layout, asset,
semantics ve görsel tema regresyonları da otomatik sinyal üretmez.

**Tetikleme:** DI kaydını, root provider sırasını, navigation callback'ini veya
page layout'unu boz; ilgili sınıf birim testlerinin tamamı geçebilir. CI app'i
cihaz/simulator üzerinde açıp yolculuk assertion'ı yapmaz.

**Önerilen fix:** Risk-temelli üç katman ekleyin: (1) root app + her page için
loading/error/empty/success, 320dp, 200% text scale ve semantics widget testleri;
(2) light/dark + TR/EN için küçük, deterministik golden matrisi; (3) en az
onboarding/legal, temel hesaplama-save-delete ve account deletion/reset için
mock backend'li `integration_test` smoke akışları. PR'da hızlı çekirdek set,
gecelik/merge queue'da platform matrisi çalıştırın.

**False-positive ve duplicate değerlendirmesi:** 03 raporunun “explicit
semantics/page widget testi eksikliği” P2 bulgusu **yeniden sayılmadı**; buradaki
yeni P1 kapsam, root wiring ile integration/golden/release yolculuğunun tamamen
yokluğudur. Flutter'ın native build job'ları uygulamanın derlendiğini gösterir,
kullanıcı yolculuğunu doğrulamaz.

### QE-08 — P2 — `flutter gen-l10n` committed çıktının temiz olduğunu doğrulamadan CI'ı geçiriyor

**Konum:** `.github/workflows/ci.yml:79-92`, `analysis_options.yaml:20-22`,
`CLAUDE.md:353-361`, `.claude/skills/l10n-add/SKILL.md:62-68`,
`.claude/skills/l10n-add/SKILL.md:110-117`

**Kanıt:** Proje generated `app_localizations*.dart` dosyalarının commit
edilmesini zorunlu tutuyor. CI checkout'tan sonra `flutter gen-l10n` çalıştırıyor
ama `git diff --exit-code -- lib/l10n/app_localizations*.dart` yapmıyor.
Generated dosyalar analyzer exclude altında. Test/build aynı runner'da yeniden
üretilmiş dosyaları kullandığı için ARB değişip generated çıktı commitlenmese
bile ephemeral çalışma ağacı kendini onarır ve CI geçebilir. Release workflow'u
da aynı davranışı tekrarlar.

**Etki:** Merge edilen git ağacı sözleşmeye aykırı ve temiz clone'da `flutter
gen-l10n` öncesi stale olabilir. Code review generated API farkını göremez;
paketleme veya editör/analyzer davranışı geliştiricinin daha önce generator
çalıştırıp çalıştırmamasına göre değişir.

**Tetikleme:** ARB key/metnini değiştir, `app_localizations*.dart` çıktısını
commit etme. CI generator dosyayı değiştirir; format/analyze/test güncel geçici
çıktıyla çalışır, dirty tree hiç kontrol edilmez.

**Önerilen fix:** Generator'dan hemen sonra yalnız beklenen generated yollar
için `git diff --exit-code -- lib/l10n/app_localizations.dart
lib/l10n/app_localizations_tr.dart lib/l10n/app_localizations_en.dart` ekleyin.
ARB JSON, `@@locale`, key/metadata/placeholder adı ve tip eşitliğini ayrı hızlı
scriptle doğrulayın. Generated dosyalar coverage denominator'ından çıkarılmalı,
fakat compile ve dirty-diff kapısından çıkarılmamalıdır.

**False-positive değerlendirmesi:** Mevcut HEAD'de TR/EN **238/238** key ve
metadata seti eşit; ARB ile generated dosyaların son değiştiren commit'i aynı
(`fa74214...`) ve güncel CI `gen-l10n` adımı başarılı. Yani bugün stale olduğuna
dair bulgu yoktur; finding gelecekteki regresyonu yakalayamayan kapı hakkındadır.

### QE-09 — P2 — Agent/doküman/CI/YAML/shell sözleşmeleri için deterministik kalite kapısı yok

**Konum:** `analysis_options.yaml:1-36`, `.githooks/pre-commit:32-57`,
`.github/workflows/ci.yml:82-92`, `.coderabbit.yaml:15-35`,
`.sourcery.yaml:9-14`

**Kanıt:** Analyzer ve pre-commit güçlü Dart kontrolleri uyguluyor ancak kapsam
yalnız `lib/` ve `test/`. CI'da agent skill fixture testi, Markdown link/path
kontrolü, YAML schema lint, `actionlint`, `shellcheck` veya runbook komut smoke
testi yok. CodeRabbit docs'u açıkça, Sourcery de `docs/**`yi ignore ediyor.
Sonuçta eksik master plan, tanımsız `Result` şablonları, yanlış branch adı,
release guard iddiası ve hardcoded tünel mevcut yeşil pipeline'da görünmüyor.

**Etki:** Agent/tooling dosyaları üretim kodu yazdırdığı ve release yönettiği
halde düz metin gibi muamele görüyor. Bu katmandaki bir typo veya eski sözleşme
uygulama kodunda çok sayıda hataya dönüşene kadar otomatik geri bildirim yok.

**Tetikleme:** Skill'e var olmayan sınıf/path ekle, workflow YAML semantiğini
boz veya dokümandaki çalıştırma komutunu eskit. Dart analyze/test bu dosyaları
okumadığı için ilgisiz şekilde yeşil kalır.

**Önerilen fix:** CI'a `actionlint`, YAML/JSON parse-schema, `shellcheck`,
Markdown link/path checker ve `.claude` referans doğrulayıcısı ekleyin. Kritik
scaffold skill'lerini temporary fixture'da çalıştırıp analyze/test eden eval
paketi kurun. Para tipi, hata modeli, l10n ve release guard gibi kuralları tek
kaynaktan okuyup çelişki testi yapın. Docs'u AI review'den tamamen çıkarmak
yerine path instruction ile doğruluk/runbook lensi uygulayın.

**False-positive ve duplicate değerlendirmesi:** AI reviewer'lar PR #37'de
çalışmış olabilir; bunlar deterministik gate değildir. 03'ün CodeRabbit docs
exclude bulgusu burada yeni bulgu sayılmadı; QE-09'un yeni özü bütün non-Dart
tooling için makinece doğrulama olmamasıdır.

### QE-10 — P2 — iOS fiziksel cihaz runbook'u `localhost` ve erişilebilir host konusunda kendi içinde çelişiyor

**Konum:** `docs/development-guide.md:51-77`,
`docs/development-guide.md:87-103`, `.claude/skills/device-deploy/SKILL.md:66-88`

**Kanıt:** Development guide ilk ortam örneğinde “iOS Simulator / fiziksel
cihaz”ı tek başlıkta birleştirip `API_BASE_URL=http://localhost:5080` veriyor.
Aynı doküman daha sonra fiziksel cihaz için `http://<local-ip>:5080` kullanıyor;
device-deploy skill'i fiziksel iPhone'da localhost/127.0.0.1'i açıkça yasaklıyor.
Ayrıca ilk örnek bu ayrımı ve LAN/firewall/TLS koşullarını açıklamıyor.

**Etki:** Onboarding komutunu kopyalayan geliştirici uygulamayı fiziksel cihazda
başlatır fakat cihaz kendi loopback'ine bağlandığından backend erişimi başarısız
olur. Bu durum API, sertifika veya uygulama bug'ı sanılarak gereksiz debug turu
yaratır.

**Tetikleme:** Guide 61-64'teki komutu bağlı gerçek iPhone hedefiyle çalıştır;
`localhost` host Mac değil iPhone'dur.

**Önerilen fix:** Simulator ve fiziksel cihazı ayrı komut/başlıklara bölün.
Fiziksel cihaz için doğrulanmış LAN IP veya güvenli ephemeral tunnel kullanın;
önce `/health` kontrolü, aynı ağ/firewall ve debug allowlist notu ekleyin. Device
skill ile guide aynı URL kaynağından üretilecek şekilde tekilleştirilmeli.

**False-positive değerlendirmesi:** Guide'ın sonraki satırında doğru `<local-ip>`
örneği vardır; bu nedenle runtime kod hatası değil P2 runbook çelişkisidir. İlk
kurulum bölümündeki yanlış birleşik başlık yine doğrudan kopyalanabilir.

## 03 raporu bağımsız doğrulama ve dedup kaydı

Aşağıdaki maddeler yeni finding toplamına dahil edilmedi. Amaç 03 raporunun
özellikle P0/P1 ve dokümantasyon/CodeRabbit iddialarını ikinci kez kaynak kodla
doğrulamak ve yanlış pozitifleri ayırmaktır.

| 03 bulgusu | Sonuç | Bağımsız kanıt / not |
|---|---|---|
| P0 — Legal metinler yayın onaylı değil | **Doğrulandı** | TR KVKK kaynağı kendisini açıkça “ŞABLON” ve doldurulacak veri sorumlusu/adres/KEP alanları olarak tanımlıyor (`kvkk_disclosure_tr.dart:3-8`), Privacy kaynakları da legal advice istiyor (`privacy_policy_tr.dart:3-5`, `privacy_policy_en.dart:3-5`). Görünür metinde yalnız “Saydın” ve e-posta var; tüzel unvan/adres yok. `CLAUDE.md:451-455` data-export endpoint'i iddia ediyor, `lib/**` çağrı yeri bulunmadı. Hukuki ihlal hükmü değil, release sign-off engeli olarak 03 sınıflandırması yerinde. |
| P0 — Varsayılan Flutter launcher ikonları | **Doğrulandı** | iOS 1024px ve Android xxxhdpi PNG'leri bağımsız görsel incelemede Flutter logosudur; ilgili iOS manifesti `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json:112-115`, Android referansı `android/app/src/main/AndroidManifest.xml:27`. Marka asset'i değildir. |
| P1 — AppConfig cold-start yarışı | **Doğrulandı** | `AppConfigCubit` default config ile başlar (`app_config_cubit.dart:6-20`), tüm provider'lar eşzamanlı load edilir (`app.dart:58-68`); scenarios ilk planı tek sefer `read` eder (`scenarios_page.dart:82-88`) ve diğer hesaplama sayfaları da `read` kullanır. Ready/loading sözleşmesi yok. |
| P1 — Onboarding Skip görülmeyen legal metni kabul ediyor | **Doğrulandı** | Skip her sayfada `_completeWithLegalAcceptance` çağırıyor (`onboarding_page.dart:237-245`); legal note yalnız son sayfa koşulunda (`onboarding_page.dart:358-369`) ve acceptance storage `onboarding_page.dart:80-96`da. Kaynak yorumunun bunu bilinçli tercih diye savunması görünür/onaylı seçim sorununu ortadan kaldırmıyor. |
| P1 — Yeni legal sürüm yeniden gösterilmiyor | **Doğrulandı** | Repository “ileride implement edilecek” diyor (`onboarding_repository.dart:5-16`); `getAcceptedLegalVersion` için production çağrı yeri yok, yalnız tanım/impl mevcut. |
| P1 — Senaryo silmede confirm/undo/erişilebilir alternatif yok | **Doğrulandı** | `Dismissible` doğrudan `onDismissed` ile siler (`scenarios_page.dart:41-68`), snackbar action yok (`scenarios_page.dart:90-100`). BLoC rollback network hatasını azaltır fakat kazara başarılı silmeyi geri almaz. |
| P1 — Onboarding/delete-account responsive overflow riski | **Statik risk doğrulandı; runtime overflow çalıştırılamadı** | Her iki sayfa scroll'suz `Column` kullanıyor (`onboarding_page.dart:220-435`, `delete_account_page.dart:72-126`); 200% text scale/320dp widget veya golden testi yok. Flutter olmayan audit ortamında somut overflow screenshot'ı üretilmedi; 03'teki ifade kesin crash değil yüksek güvenli test boşluğu/risk olarak okunmalı. |
| P2 — Doküman ve otomatik review çelişkileri | **Doğrulandı, yeni sayılmadı** | README hâlâ Flutter 3.41.0 (`README.md:3`), pin 3.41.4; CodeRabbit `master` base ve docs exclude (`.coderabbit.yaml:12-21`), CI `main/development` (`ci.yml:13-17`), architecture oku da yanlış (`.coderabbit.yaml:30`). PR #37'nin base'i `main` olmasına rağmen `coderabbitai` iki ayrı tarihte review/comment üretti; dolayısıyla dosyadaki `base_branches` niyeti ile gerçek bot davranışı uyuşmuyor. Bunun nedeni schema ignore, dashboard override veya manuel tetik olabilir; kanıt tek başına hangisini ispatlamaz. Ayrıca CodeRabbit'in sabit `tr_TR` currency talimatı (`.coderabbit.yaml:29`) artık EN locale desteğiyle uyumsuz. |

## Doğrulanmış temiz kontroller

- Güncel `main` CI: format, `flutter analyze --fatal-infos`, l10n generation ve
  **379 test** başarılı. Bu rapor bunların başarısız olduğunu iddia etmiyor.
- `analysis_options.yaml` strict casts/raw types/inference, `avoid_print:error`
  ve `unawaited_futures:error` uyguluyor. Generated l10n exclusion kasıtlı ve
  dokümante; eksik olan generated dirty-diff/coverage ayrımıdır.
- TR/EN ARB key setleri **238 / 238**, metadata key setleri eşit, `@@locale`
  değerleri `tr` / `en`. ARB ve üç generated dosyanın son değiştiren commit'i
  aynı; güncel CI generator adımı başarılı.
- `mockito` kullanımı ve code-generated mock bulunmadı; testler `mocktail`
  sözleşmesine uyuyor.
- `.githooks/pre-commit` executable ve format + fatal analyze + tam test setini
  fail-closed çalıştıracak şekilde yazılmış. Ancak bu checkout'ta
  `core.hooksPath` ayarlı değildi; hook aktivasyonu clone ile taşınmadığı için
  CI/branch rules yerine güvenlik sınırı kabul edilmedi.
- `.metadata` tracked ve Flutter `3.41.4` commit'i
  `ff37bef603469fb030f2b72995ab929ccfc227f0` ile tutarlı. `.gitignore`da yer
  almasına rağmen tracked dosya güncellemeleri Git tarafından izlenmeye devam
  eder; bu durum tek başına finding yapılmadı.
- `pubspec.lock` tracked; Flutter uygulaması için doğru ve `.gitignore` yorumu
  bunun niyetini açıklar. Coverage artifacts ve secrets ignore altında.
- `.coderabbit.yaml` ve `.sourcery.yaml` generated/build ağaçlarını dışlıyor;
  gürültü azaltma niyeti doğru. Sorun docs/tooling'in tamamının doğrulamasız
  kalması ve CodeRabbit base/architecture talimatlarının eski olmasıdır.

## Önerilen uygulama sırası

1. **Release'i fail-closed yapın:** reusable quality job + tag SHA check +
   branch ruleset; test/analyze/coverage geçmeden staging dahil mağaza job'u
   başlamasın.
2. **Coverage gerçeğini normalize edin:** generated code hariç, tüm production
   kaynakları dahil denominator; mevcut baseline gate, patch gate ve planlı
   `%60+` yükselişi.
3. **Agent toolchain'i tekrar çalışabilir hale getirin:** tracked master plan,
   Decimal sözleşmesi, gerçek AppError API'sine uyan scaffold şablonları ve
   hardcoded tünelin kaldırılması.
4. **Kritik yol testlerini ekleyin:** root/widget + integration smoke + sınırlı
   golden/semantics matrisi; 03'teki onboarding/legal/config/delete riskleri ilk
   acceptance senaryoları olsun.
5. **Non-Dart kalite kapılarını kurun:** generated l10n dirty diff,
   actionlint/shellcheck/YAML/Markdown/path kontrolleri ve `.claude` scaffold
   eval'leri.

## Sonuç

Projenin test disiplini gerçek ve güncel CI yeşildir; temel sorun test sayısı
değil, kalite iddialarının merge/release kararına bağlanmaması ve agent
şablonlarının kanonik mimariden kopmuş olmasıdır. İlk üç öneri tamamlanmadan
yeşil CI “release edilebilir”, master-review launcher “çalışabilir” veya `%60
coverage sağlandı” anlamına gelmemelidir.
