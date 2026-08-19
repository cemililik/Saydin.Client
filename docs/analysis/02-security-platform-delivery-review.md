# Saydın Client — Güvenlik, Platform ve Teslimat Review

**Tarih:** 2026-08-18
**Review türü:** Salt-okunur, kanıt odaklı, saldırgan/failure-mode incelemesi
**Kapsam:** Network, error handling, observability, storage, platform, DI/bootstrap, Android, iOS, dependency/supply-chain, CI/release, signing, privacy/KVKK ve ilgili test/dokümanlar
**Kod değişikliği:** Yok

## 1. Yönetici özeti

İnceleme sonucunda **22 bulgu** kaydedildi:

| Seviye | Adet | Anlamı |
|---|---:|---|
| P0 | 0 | Doğrudan ve hâlen sömürülebilen/servisi durduran acil durum bulunmadı |
| P1 | 7 | Store yayını, veri sahibi hakkı, PII veya signing zinciri için yayın öncesi kapatılmalı |
| P2 | 11 | Yakın vadede düzeltilmesi gereken önemli güvenlik/güvenilirlik borcu |
| P3 | 4 | Savunma derinliği, tutarlılık ve geliştirici deneyimi iyileştirmesi |

En önemli sonuç, tekil bir kod hatasından çok **release güven modelinin depoda anlatılan modelle fiilen aynı olmaması**dır. 2026-08-18 tarihli GitHub API kontrolünde `main` branch protection yoktur, repository ruleset listesi boştur ve hiç `production`/`staging` environment tanımlı değildir. Buna rağmen `.github/workflows/release.yml:219-221,372-374` environment adına referans vermenin manuel onay yarattığını varsayar. GitHub'ın resmî davranışında var olmayan environment ilk çalışmada **koruma kuralı olmadan** yaratılır. Ayrıca release guard yalnız tag commit'inin `main` atası olmasını denetlemekte, CI sonucunu veya `main` HEAD eşitliğini denetlememektedir (`.github/workflows/release.yml:85-94`). Dolayısıyla write erişimli bir hesabın tag push'u, dokümante edilen insan onayı ve CI kapısı olmadan signing secret'larına ve store upload adımlarına ulaşabilir.

İkinci kritik küme veri sahibi haklarıdır. Backend silme isteği başarısız olduğunda bile yerel secure storage ve `X-Device-ID` silinmektedir (`lib/features/account/presentation/cubit/account_deletion_cubit.dart:39-61`, `lib/features/account/data/repositories/account_data_repository_impl.dart:31-58`). Sunucu kaydı eski device ID ile bağlıysa kullanıcı sonraki denemede o kaydı hedefleme kabiliyetini kaybedebilir. Bu davranış hem `CLAUDE.md:453-455` sözleşmesine hem de uygulamada gösterilen silme/aydınlatma vaatlerine ters düşmektedir.

Üçüncü kritik küme production yapılandırmasıdır. GitHub repository variable anlık görüntüsünde `API_URL_PRODUCTION` ve `API_URL_STAGING` aynı `ngrok-free.dev` tüneline işaret etmektedir. Tam URL bu raporda gereksiz yere tekrar edilmemiştir. Release build'i ayrıca `SENTRY_DSN` veya pin geçmemektedir. Sonuç: staging/production izolasyonu yoktur, production binary kalıcı ve sahipliği doğrulanmış bir production origin yerine geliştirme tüneline bağlanmaya hazırdır ve rollout sırasında crash observability kapalıdır.

Bu rapor hukuki görüş değildir. Ancak metin ile teknik gerçeklik arasındaki uyuşmazlıklar doğrulanmıştır; KVKK hukuki dayanakları, veri sorumlusu bilgileri, aktarım ve saklama süreleri ayrıca yetkin hukuk danışmanı/DPO tarafından onaylanmalıdır.

## 2. Yöntem ve doğrulama durumu

### İncelenen yüzey

- `CLAUDE.md` ve `docs/architecture.md` baştan sona okundu.
- `lib/core/network/**`, `lib/core/error/**`, `lib/core/observability/**`, `lib/core/storage/**`, `lib/core/platform/**`, `lib/core/di/**`, `lib/main.dart`, `lib/app.dart` incelendi.
- `android/**` ve `ios/**` altındaki kaynak, manifest, XML/plist, Gradle, CocoaPods, Xcode proje/scheme ve signing/export dosyaları incelendi; binary görsel asset'ler envanter ve kaynak kontrol durumu açısından kontrol edildi.
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.github/**`, `.githooks/**`, `.coderabbit.yaml`, `.sourcery.yaml`, `.gitignore` ve ilişkili geliştirme/release dokümanları incelendi.
- İlgili network, error, observability, account deletion ve lifecycle testleri incelendi.
- Tracked dosyalarda özel anahtar/token imzası ve yaygın signing artifact uzantıları tarandı.

### Çalıştırılan salt-okunur kontroller

- Workflow YAML parse, plist lint, Android XML parse, `bash -n` hook kontrolü ve Gradle wrapper JAR bütünlük kontrolü başarılı oldu.
- `android/gradle/wrapper/gradle-wrapper.properties:3-4` dağıtım SHA-256'sını sabitlemektedir; wrapper JAR SHA-256 değeri ayrıca kaydedildi.
- `pubspec.lock` içindeki 116 hosted Pub paketi OSV API'ye karşı sorgulandı: **116/116 sorgu başarılı, bilinen eşleşme 0**. Bu yalnız 2026-08-18 OSV anlık görüntüsüdür; “güvenlik açığı yok” garantisi değildir.
- Yerel ortamda `flutter`, `dart`, `actionlint`, `shellcheck`, `pod` ve `osv-scanner` bulunmadığı için yerel `flutter analyze/test/build` çalıştırılamadı. Bu bir proje hatası olarak değerlendirilmedi.
- Buna karşılık son `main` CI çalışması [GitHub Actions run 32134705408](https://github.com/cemililik/Saydin.Client/actions/runs/32134705408) üzerinde analyze ve test başarılıdır; Android/iOS build job'ları workflow koşulu nedeniyle `main` push'unda **skipped** olmuştur.
- 2026-08-18 GitHub API anlık görüntüsü: `main` protection → 404/not protected; rulesets → `[]`; environments → `[]`; release workflow runs → `[]`; Actions policy → `allowed_actions=all`, `sha_pinning_required=false`; default `GITHUB_TOKEN` izni → `contents: read`.
- Repository variable isim/değer kontrolü: staging ve production API URL değerleri aynıdır ve aynı `ngrok-free.dev` origin'ini kullanmaktadır. Secret değerleri okunmamış, yalnız secret isimleri ve yapılandırmanın varlığı kontrol edilmiştir.

## 3. P1 bulgular

### SEC-01 — P1 — Release governance / yetkilendirme: Belgelenen production onayı ve CI kapısı fiilen yok

**Kanıt**

- Workflow yorumu ve dokümanlar production'ın manuel onay beklediğini söyler: `.github/workflows/release.yml:24-27`, `CLAUDE.md:245-277`, `docs/development-guide.md:250-278`.
- Store job'ları yalnız environment adına referans verir: `.github/workflows/release.yml:215-221,367-374`; YAML içinde reviewer veya protection rule tanımlanamaz.
- 2026-08-18 API anlık görüntüsünde environments `[]`, `main` branch protection 404 ve rulesets `[]` idi.
- GitHub, var olmayan bir environment workflow'da ilk kez referans edildiğinde onu koruma kuralı/secret olmadan otomatik yaratır. Required reviewer ayrıca environment üzerinde yapılandırılmalıdır ([GitHub environment yönetimi](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), [deployment environments](https://docs.github.com/en/actions/concepts/workflows-and-actions/deployment-environments)).
- Guard yalnız `git merge-base --is-ancestor` uygular (`.github/workflows/release.yml:85-94`). Tag'in `main` HEAD olması, aynı SHA için CI success bulunması veya required status check aranmaz.
- Release job'larında format/analyze/test/release smoke/security scan yoktur; `flutter pub get` sonrasında doğrudan build ve store upload yapılır (`.github/workflows/release.yml:223-365,376-451`).
- Main CI'daki platform build'leri yalnız PR veya development push'unda koşar (`.github/workflows/ci.yml:196-203,253-260`); son main run'da her iki platform build'i skipped idi.
- `CLAUDE.md:254-255,297-301` lightweight tag'i yasaklar; workflow ise annotated body yoksa commit subject'e fallback edip devam eder (`.github/workflows/release.yml:138-150`).
- Release workflow'un GitHub run geçmişi 2026-08-18 itibarıyla boştur; store yolu RC dry-run ile kanıtlanmamıştır.

**Etki / arıza-saldırı senaryosu**

Write erişimli hesabın ele geçirilmesi, hatalı direct push veya bakım hatası sonrası eski ama `main` atası olan bir commit'e production tag'i basılır. Guard geçer; protection/ruleset ve environment reviewer olmadığı için imzalı AAB doğrudan `%10` production rollout'a, IPA TestFlight'a ilerler. Aynı SHA'nın test/build sonucu başarısız veya hiç çalışmamış olabilir. Dokümandaki “manuel approval” güvenlik varsayımı gerçek değildir.

**Remediation**

1. GitHub'da `main` için ruleset/branch protection oluşturun: PR zorunluluğu, required reviews/CODEOWNERS, conversation resolution, signed commit/tag tercihi ve required `Analyze & Test`, OSV ve iki platform build check'i.
2. `production` ve `staging` environment'larını önceden oluşturun. Production'a bağımsız required reviewer, self-review yasağı, deployment branch/tag policy ve mümkünse wait/custom protection ekleyin.
3. Release guard'da tag commit == onaylanmış release SHA/`main` HEAD ve o SHA'nın beklenen CI conclusion'ları success kontrolünü GitHub API ile fail-closed yapın.
4. Lightweight tag'i tag object türü (`git cat-file -t`) ile reddedin.
5. Store adımlarından önce aynı job graph'ında release-mode compile smoke, analyze, test ve vulnerability policy çalıştırın. İlk olarak store'a yazmayan RC/dry-run yapın.

**Belirsizlik / false-positive sınırı:** GitHub ayarları zamanla değişebilir; kanıt 2026-08-18 anlık görüntüsüdür. Ancak bu tarihte dokümante edilen manuel onay mevcut değildir.

### SEC-02 — P1 — Environment/transport boundary: Production ve staging aynı geliştirme tüneline bağlı

**Kanıt**

- Release build URL'yi repository variables'dan alır (`.github/workflows/release.yml:295-317,414-432`).
- 2026-08-18 `gh variable list` anlık görüntüsünde `API_URL_PRODUCTION == API_URL_STAGING`; ikisi de aynı `ngrok-free.dev` tünel origin'idir ve aynı tarihte güncellenmiştir.
- `ApiBaseUrlValidator` herhangi bir HTTPS host'u kabul edip hemen döner (`lib/core/network/api_base_url_validator.dart:61-73`); production hostname allowlist'i yoktur.
- Her istek persistent `X-Device-ID` taşır (`lib/core/network/device_id_interceptor.dart:31-37`); hesaplamalar/senaryolar asset, tarih ve tutar payload'ı gönderir (`lib/features/what_if/data/repositories/what_if_repository_impl.dart:40-60`, `lib/features/scenarios/data/repositories/scenarios_repository_impl.dart:58-81`).
- `CLAUDE.md:428-432` URL'nin hardcode edilmemesini ve aktif tünelin commit geçmişine yazılmamasını söyler; `.claude/skills/device-deploy/SKILL.md:14,37,44` aynı tüneli commit etmiştir.

**Etki / arıza-saldırı senaryosu**

Production tag'i atıldığında store binary kalıcı production origin yerine geliştirme tüneline bağlanır. Tünel kapanırsa tüm network özellikleri kesilir; yanlış backend instance'ı ayağa kalkarsa production kullanıcı device ID ve finansal hesaplama girdileri staging/dev veri düzlemine gider. Tünel sahipliği/rotasyonu yanlış yönetilirse veri yanlış origin'e aktarılabilir. Staging ve production arasında erişim, veri saklama, rate limit ve gözlemlenebilirlik izolasyonu yoktur.

**Remediation**

- Kalıcı, sahipliği doğrulanmış ayrı `api.saydin.app` ve staging origin'leri oluşturun; DNS/TLS/hosting ownership ve veri ortamı izolasyonunu belgeleyin.
- Validator ve release preflight'a scheme + tam host + port + path/userinfo/query/fragment kuralları ekleyin. Production host allowlist dışındaysa build'i durdurun.
- Repository variable'larını environment-scoped variable'a taşıyın; production değeri yalnız production environment'ta bulunsun.
- Mevcut tüneli production variable'dan kaldırın; commit edilmiş tünel/device deploy metadatasını temizleyip gerekirse tünel adresini rotate edin.

**Belirsizlik / false-positive sınırı:** Tünelin arkasındaki servisin içeriği incelenmedi. Bulgu, same-origin yapılandırması ve production isolation yokluğu açısından kesindir.

### SEC-03 — P1 — KVKK silme hakkı: Backend başarısızken retry kimliği geri dönülmez biçimde yok ediliyor

**Kanıt**

- `AccountDeletionCubit` backend'i best-effort kabul eder ve false/exception sonrasında da local wipe çağırır (`lib/features/account/presentation/cubit/account_deletion_cubit.dart:39-61`). Davranış testte bilinçli biçimde sabitlenmiştir (`test/features/account/presentation/cubit/account_deletion_cubit_test.dart:106-127,166-195`).
- Wipe, bütün secure storage'ı siler ve device ID memory cache'ini resetler (`lib/features/account/data/repositories/account_data_repository_impl.dart:31-58`).
- Backend isteği yalnız 2xx için true döner; 404, 501, 5xx ve network false olur (`lib/features/account/data/repositories/account_data_repository_impl.dart:89-108`).
- Tüm API istekleri `X-Device-ID` ile ilişkilendirilir (`lib/core/network/device_id_interceptor.dart:5-17,31-37`). Secure storage boşalınca yeni UUID üretilir (`lib/core/network/device_id_interceptor.dart:58-78`).
- `CLAUDE.md:453-455` backend 200 olmadan local cleanup başlamamasını zorunlu kılar; gerçek kod tersidir.
- Domain sözleşmesi ve state yorumları da kendi içinde sürüklenmiştir: `lib/features/account/domain/repositories/account_data_repository.dart:3-6,20-27` backend account yok/best-effort derken `lib/features/account/presentation/cubit/account_deletion_state.dart:18-20` 404/501'i başarı yorumu yapar; gerçek repository bunları false sayar.

**Etki / arıza-saldırı senaryosu**

Sunucu DELETE'i hiç almadan bağlantı kesilir veya 5xx döner. İstemci yine eski device ID'yi siler, onboarding'e döner ve sonraki istekte yeni UUID üretir. Sunucu kaydı eski ID ile bağlıysa kullanıcı eski kaydı hedefleyen authenticated/pseudonymous retry kabiliyetini kaybeder; kayıt orphan kalabilir. “Partial success + e-posta gönderin” mesajı teknik olarak telafi edilemeyen bir identity loss'u kullanıcıya devreder. Ters yarışta sunucu DELETE'i işleyip yanıt kaybolursa istemci sonucu doğrulayamaz.

**Remediation**

- Silme talebini server-generated request ID/tombstone ile idempotent ve sorgulanabilir yapın. Device ID yerine kısa ömürlü, silme özelinde tekrar kullanılabilir proof/token kullanın.
- Backend 2xx/accepted + status endpoint ile doğrulanmadan device identity'yi silmeyin. Yerel finansal verinin acil silinmesi gerekiyorsa device-ID/proof'u ayrı güvenli quarantine alanında yalnız deletion retry için sınırlı süre tutun.
- Retry/backoff ve “response lost after commit” senaryolarını kontrat testiyle kapsayın. 404 semantiğini açıkça tanımlayın: kullanıcı yoksa idempotent success olabilir; endpoint yoksa failure olmalıdır.
- UI'da “tamamlandı” ile “sunucu talebi bekliyor” durumunu ve otomatik retry durumunu ayrı gösterin.

**Belirsizlik / false-positive sınırı:** Backend veri anahtarlama modeli bu repoda değildir. Orphan senaryosu, `X-Device-ID`'nin quota/dedupe ve account endpoint için aynı identity olduğuna dayalı güçlü bir çıkarımdır. Identity farklıysa etki azalır; buna rağmen doküman-kod sözleşme ihlali kesindir.

### SEC-04 — P1 — Privacy/KVKK doğruluğu: Yayına hazır olmayan şablon, eksik veri sorumlusu ve gerçekle çelişen beyanlar

**Kanıt**

- Shipped TR/EN gizlilik metni kendisini “yer tutucu/template” olarak tanımlar (`lib/features/legal/data/sources/privacy_policy_tr.dart:3-5`, `lib/features/legal/data/sources/privacy_policy_en.dart:3-5`).
- KVKK TR kaynak yorumu veri sorumlusu, adres, başvuru üyesi ve KEP yer tutucularının doldurulmasını ister (`lib/features/legal/data/sources/kvkk_disclosure_tr.dart:5-8`); gösterilen metin yalnız “Saydın” ve e-posta verir (`lib/features/legal/data/sources/kvkk_disclosure_tr.dart:19-25,89-93`). Gerçek tüzel kişi unvanı, adres ve KEP yoktur.
- Politika sunucuda kullanıcıya özel veri olmadığını, kaydedilmiş senaryoların yerel olduğunu ve finansal portföy bilgisi toplanmadığını söyler (`lib/features/legal/data/sources/privacy_policy_tr.dart:18-25,46-52`; EN `lib/features/legal/data/sources/privacy_policy_en.dart:18-25,46-53`). Oysa persistent device ID her istekte gönderilir; saved scenario asset adı/sembolü, tarihler, tutar, tür ve `extraData` ile backend'e POST edilir (`lib/features/scenarios/data/repositories/scenarios_repository_impl.dart:58-81`). Hesaplama payload'ı da asset/tarih/tutar taşır (`lib/features/what_if/data/repositories/what_if_repository_impl.dart:40-60`).
- UUID “anonim” olarak adlandırılır (`lib/features/legal/data/sources/kvkk_disclosure_tr.dart:28-37`), ancak süreklidir ve quota/dedupe için kullanılır; teknik olarak yeniden ilişkilendirilebilir pseudonymous identifier'dır.
- KVKK metni yerel verinin uninstall ile silindiğini vaat eder (`lib/features/legal/data/sources/kvkk_disclosure_tr.dart:62-67`, EN `lib/features/legal/data/sources/kvkk_disclosure_en.dart:56-61`). Device ID iOS Keychain'de `first_unlock_this_device`, `synchronizable:false` ile saklanır (`lib/core/storage/secure_storage_factory.dart:18-34`). Bu seçenekler cihaz/iCloud sınırını yönetir, uninstall silinmesini garanti etmez. Apple DTS, uninstall sonrası Keychain kalıcılığının tarihsel davranış olduğunu ve dokümante edilmiş bir silme garantisi bulunmadığını belirtir ([Apple DTS açıklaması](https://developer.apple.com/forums/thread/36442)); Apple veriyi tamamen kaldırmak için `SecItemDelete` çağrısını tarif eder ([Apple Keychain dokümanı](https://developer.apple.com/documentation/security/using-the-keychain-to-manage-user-secrets)). Uninstall sırasında uygulama bu çağrıyı çalıştıramaz.
- Sentry'nin “en geç 90 gün” saklama süresi (`lib/features/legal/data/sources/privacy_policy_tr.dart:51-52`, `lib/features/legal/data/sources/kvkk_disclosure_tr.dart:62-67`) repository tarafından enforce edilemez ve Sentry project ayarı bu incelemede doğrulanmamıştır.

**Etki / arıza-saldırı senaryosu**

Kullanıcı, store reviewer veya veri sahibi; yalnız yerel/anonim veri işlendiği ve uninstall ile silindiği beyanına güvenir. Gerçekte device-pseudonym ile finansal senaryo payload'ı backend'e gider ve iOS Keychain item'ı uninstall/reinstall sonrasında kalabilir. Başvuru sırasında gerçek veri sorumlusu/adres/KEP bulunmadığından hak kullanımı aksar. App Store/Play Data Safety formları bu metne göre doldurulursa yanlış disclosure riski doğar.

**Remediation**

- Store submission'ı, hukuk/DPO onaylı gerçek veri sorumlusu kimliği, adresi, KEP/başvuru yöntemi, alıcılar, işleme dayanağı, yurtdışı aktarım mekanizması, gerçek saklama süreleri ve silme SLA'sı eklenene kadar bloke edin.
- “Anonim” yerine doğru bağlamda “pseudonymous device identifier” kullanın; backend'e gönderilen tüm payload kategorilerini ve saved scenario saklamasını açıkça yazın.
- “Uninstall tüm veriyi siler” mutlak vaadini kaldırın. İlk açılışta previous-install marker/key entanglement ile stale Keychain item'ını tespit edip silme veya yeni ID üretme tasarlayın; explicit account deletion `deleteAll()` sonucunu doğrulasın.
- Sentry retention/export/region ayarlarını IaC veya release checklist ile kanıtlayın ve store privacy formlarıyla otomatik drift kontrolü kurun.

**Belirsizlik / false-positive sınırı:** Bunun bir hukuk ihlali olup olmadığına dair nihai hüküm verilmemiştir. Teknik veri akışı ile kullanıcıya gösterilen beyanların çelişkisi ve eksik yer tutucular kesindir.

### SEC-05 — P1 — Observability/PII: Sentry scrubber yapılandırılmış context ve küçük finansal değerleri geçiriyor

**Kanıt**

- Kod “kalan tüm event/breadcrumb içeriklerinin” scrub edildiğini ve finansal verinin hiçbir koşulda gitmemesini vaat eder (`lib/main.dart:47-55`, `lib/core/observability/sentry_pii_scrubber.dart:3-14`).
- Tutar regex'i yalnız 4+ haneli sayıları veya en az iki ondalık haneli 1-3 haneli sayıları yakalar (`lib/core/observability/sentry_pii_scrubber.dart:67-76`). `amount=99`, `amount=9.5`, `price=0.5` olduğu gibi kalır. Testler 1-3 haneli bütün sayıları teknik kabul ederek korumayı sabitler (`test/core/observability/sentry_pii_scrubber_test.dart:27-30`).
- `_scrubContexts`, yalnız `Map<String,Object?>` değerlerini scrub eder; typed context nesnelerini olduğu gibi geçirir (`lib/core/observability/sentry_pii_scrubber.dart:391-405`). Kullanılan Sentry 8.14.2'nin `Contexts` nesnesi `SentryDevice`, `SentryResponse` ve `SentryFeedback` typed değerleri taşır; `SentryDevice` içinde `name` ve `deviceUniqueIdentifier` alanları vardır ([8.14.2 Contexts kaynağı](https://raw.githubusercontent.com/getsentry/sentry-dart/8.14.2/dart/lib/src/protocol/contexts.dart), [8.14.2 SentryDevice kaynağı](https://raw.githubusercontent.com/getsentry/sentry-dart/8.14.2/dart/lib/src/protocol/sentry_device.dart)).
- `sendDefaultPii=false` SDK'nın varsayılan identifier toplamasını sınırlar (`lib/main.dart:56-59`), fakat custom/plugin-created typed context event'e girdikten sonra scrubber bunu kaldırmaz.
- `_scrubMessage` formatted ve params'i temizlerken `message.template` değerini aynen bırakır (`lib/core/observability/sentry_pii_scrubber.dart:302-310`). `_scrubUrl` query ve UUID'yi temizler ama UUID olmayan path identifier'larını bırakır (`lib/core/observability/sentry_pii_scrubber.dart:440-446`).
- Event testleri message, attachment, exception, user, fingerprint, transaction ve request'i kapsar; typed device/response/feedback context, message template, düşük tutar ve non-UUID path ID kapsamı yoktur (`test/core/observability/sentry_pii_scrubber_test.dart:184-293`).

**Etki / arıza-saldırı senaryosu**

Bir plugin veya gelecekteki scope enrichment `SentryDevice(name: ..., deviceUniqueIdentifier: ...)` ekler; beforeSend typed nesneyi aynen geçirir. Alternatif olarak `FormatException('amount=99')` veya message template küçük tutarı taşır. DSN etkin bir build'de device identifier ya da finansal değer Sentry'ye aktarılır ve “kişisel veri sansürlenir” disclosure'ı ihlal edilir.

**Remediation**

- Deny-by-default event şeması kullanın: typed context'leri güvenli alanlardan yeniden kurun; `deviceUniqueIdentifier`, device name, response body/header ve feedback contact alanlarını drop edin.
- Finansal değer redaksiyonunu yalnız regex tahminiyle yapmayın. Call-site'ta structured amount/date/asset değerlerinin event metnine hiç girmemesini sağlayın; exception allowlist/normalization kullanın. Serbest metinde sayı gerekiyorsa HTTP status'u bağlamsal key üzerinden koruyup diğer sayıları redact edin.
- `message.template`, URL path segmentleri, span descriptions/data, measurements ve feedback için test ekleyin. Sentry SDK upgrade'lerinde serialize edilmiş envelope snapshot testini gerçek 8.14.2/target sürümle çalıştırın.

**Belirsizlik / false-positive sınırı:** Resmî release workflow şu an DSN geçmediği için store path'inde Sentry gönderimi kapalıdır (SEC-06). Bulgu, DSN etkin local/alternatif build ve hedeflenen production konfigürasyonu için ulaşılabilirdir; latent privacy boundary açığıdır.

### SEC-06 — P1 — Operasyonel güvenlik: Release build'lerinde Sentry kapalı ve symbol upload zinciri yok

**Kanıt**

- DSN yalnız `--dart-define=SENTRY_DSN` ile gelir; yoksa boş/no-op'tur (`lib/main.dart:34-40`, `CLAUDE.md:443-449`, `docs/architecture.md:396`).
- Android ve iOS release build komutları yalnız `API_BASE_URL` ve `APP_ENV` geçer; `SENTRY_DSN` yoktur (`.github/workflows/release.yml:306-317,425-432`).
- `tracesSampleRate=0.2` konfigüre edilmiş olsa da DSN olmadan transaction gönderilmez (`lib/main.dart:41-45`).
- Workflow'da Sentry Dart debug info/native dSYM/Android mapping upload adımı veya `sentry_dart_plugin` yoktur. iOS `uploadSymbols=true` (`ios/ExportOptions.plist:5-12`) Apple'a symbol gönderir; Sentry symbolication sağlamaz.
- Production rollout karar dokümanı crash-free rate'e dayanır (`docs/development-guide.md:278-280`), ancak o metriğin production kaynağı release build'inde etkin değildir.

**Etki / arıza-saldırı senaryosu**

Production `%10` rollout crash, TLS failure, platform exception veya deletion regressions üretir. Sentry event gelmediği için “crash-free” sessizlik başarı sanılabilir; rollback/promote kararı eksik veriye dayanır. DSN sonradan eklense bile symbols/mapping yüklenmezse release stack trace'leri tanılanamaz.

**Remediation**

- DSN'yi environment-scoped secret/variable ile iki release build'e de ekleyin; boş DSN'yi production build preflight'ta fail-closed yapın.
- Sentry Dart/native debug file, iOS dSYM ve Android ProGuard/R8 mapping upload'ını exact release/version ile kurun; upload başarısızsa production store upload'ı durdurun veya açık risk onayı isteyin.
- RC'de kontrollü handled exception, native crash sembol çözümü ve scrubbed envelope smoke testi yapın. Rollout SLO'sunu gerçek dashboard alarmıyla bağlayın.

**Belirsizlik / false-positive sınırı:** Store console veya harici pipeline'da manuel symbol upload yapılıyor olabilir; repository'de kanıtı yoktur. DSN'nin workflow'da geçmemesi kesindir.

### SEC-07 — P1 — Supply chain/signing: Secret-bearing release job'ları mutable Action tag'leri çalıştırıyor

**Kanıt**

- CI ve release tüm Actions'ı mutable major/minor tag'lerle kullanır: örnekler `actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/setup-java@v4`, `maxim-lobanov/setup-xcode@v1`, `apple-actions/*@v1/v3`, `r0adkll/upload-google-play@v1.1.5`, `softprops/action-gh-release@v2` (`.github/workflows/release.yml:79,110,224-235,320,346-357,377-407,439-451,595-617`).
- Android signing keystore/password'ları ve Google service account aynı job'a açılır (`.github/workflows/release.yml:249-293,346-365`); iOS certificate ve App Store private key üçüncü taraf action'lara açılır (`.github/workflows/release.yml:400-451`).
- Repository Actions policy 2026-08-18'de `allowed_actions=all`, `sha_pinning_required=false` idi.
- GitHub, üçüncü taraf Action için full-length commit SHA'nın tek immutable referans olduğunu ve `GITHUB_TOKEN`/secret'lar için least privilege uygulanmasını önerir ([GitHub secure use](https://docs.github.com/en/actions/reference/security/secure-use?presscats=25)).
- Release checkout'ları `persist-credentials:false` belirtmez (`.github/workflows/release.yml:224-227,377-379,595-597`). Dış ayarda default token izni `contents: read` olduğu için yazma etkisi sınırlıdır; yine de token çalışma ağacında kalır. CI checkout'larının bunu kapatması olumlu kontroldür (`.github/workflows/ci.yml:35-37,69-71,147-149,206-208,263-265`).

**Etki / arıza-saldırı senaryosu**

Bir Action tag'i upstream'de ele geçirilir/yeniden işaretlenir veya bağımlı action zinciri compromise olur. Runner aynı adımda signing key, service-account JSON ya da App Store API private key'e erişir ve bunları exfiltrate edebilir; saldırgan kötü niyetli store build'i yükleyebilir. Branch review tek başına upstream tag mutasyonunu yakalamaz.

**Remediation**

- Her Action'ı full 40-character commit SHA'ya pinleyin, yanında insan okunur sürüm yorumu tutun. Repository `sha_pinning_required=true` ve `allowed_actions=selected` politikasını etkinleştirin.
- `permissions: contents: read` workflow seviyesinde explicit olsun; yalnız GitHub release job'ında `contents: write` yükseltin. Tüm checkout'larda `persist-credentials:false` kullanın.
- Signing/upload'ı minimal ayrı job'lara bölün; her job yalnız gereken secret'ı alsın. Service account/App Store key'lerini en düşük store rolüyle, düzenli rotasyonla ve mümkünse kısa ömürlü federated identity ile yönetin.
- Dependency review ve Action provenance kontrolünü release gate'e ekleyin.

**Belirsizlik / false-positive sınırı:** İnceleme herhangi bir Action'ın kötü niyetli olduğunu iddia etmez. Risk, mutable referans + yüksek değerli secret bileşimidir.

## 4. P2 bulgular

### SEC-08 — P2 — API URL validation fail-closed değil; HTTPS için authority sınırı yok

**Kanıt:** Her HTTPS URL koşulsuz kabul edilir (`lib/core/network/api_base_url_validator.dart:61-73`); userinfo, özel port, query, fragment veya base path reddedilmez. Validator yalnız lazy `ApiClient` factory içinde çalışır (`lib/core/di/injection.dart:69-82`), bu nedenle dokümandaki startup fail-fast iddiasına rağmen `configureDependencies()` sırasında çözülmeyebilir. Testler HTTPS hostname/authority, userinfo, query/fragment ve DI startup davranışını kapsamıyor (`test/core/network/api_base_url_validator_test.dart`).

**Senaryo/etki:** Release variable typo'su veya repo ayarı compromise edilerek `https://attacker.example/...` verilir; uygulama açılır, ilk network feature'ında device ID ve payload yanlış origin'e gider. Malformed değer store build'inde değil kullanıcı cihazında patlar.

**Remediation:** Base URL'yi bootstrap başında eager validate edin; production için tam hostname/port allowlist, boş userinfo/query/fragment ve beklenen base path kuralı koyun. Aynı validator'ı workflow preflight'ta çalıştırın ve iki platform artifact'inin embedded define'ını smoke test edin.

### SEC-09 — P2 — GitHub Actions script/output injection: API URL expression'ları doğrudan shell'e yerleştiriliyor

**Kanıt:** Repository variables `run:` scriptine doğrudan template expansion ile yazılır (`.github/workflows/release.yml:295-304,414-423`) ve output daha sonra tırnaksız CLI argümanına interpolate edilir (`.github/workflows/release.yml:313-317,427-432`). CI debug build aynı problemi intermediate `env` + quoting ile doğru çözmüştür (`.github/workflows/ci.yml:231-244,286-297`). GitHub expression'ların shell parse'ından önce metne dönüştüğünü ve intermediate environment variable önerdiğini açıklar ([GitHub script injection](https://docs.github.com/en/actions/concepts/security/script-injections)).

**Senaryo/etki:** Repository/environment variable düzenleme yetkisi ele geçirilen veya yanlışlıkla newline/metacharacter içeren URL; shell komutu veya `$GITHUB_OUTPUT` alanı enjekte eder. Job signing/store secret'larına eriştiği için etki yüksektir; saldırganın önceden repository setting yazma yetkisi gerekmesi nedeniyle P2'dir.

**Remediation:** Değerleri `env:` üzerinden geçirip `"$API_URL"` ile quote edin; output yazarken random delimiter ve newline reddi kullanın. URL'yi strict parser/allowlist ile doğrulamadan signing job'ına geçmeyin.

### SEC-10 — P2 — Certificate pinning güvenlik kararı tamamlanmamış; mevcut implementasyonu açmak availability riski

**Kanıt:** Pin yoksa no-op (`lib/core/network/certificate_pinning.dart:49-67`), release pin geçmez (`lib/core/network/certificate_pinning.dart:28-34`, `.github/workflows/release.yml:313-317,427-432`). Kod tüm leaf DER'i hash'ler (`lib/core/network/certificate_pinning.dart:41-45,88-108`), SPKI değil; expiration mekanizması yoktur. Doküman mimari çizimi handshake'in pin ile doğrulandığı izlenimi verir (`docs/architecture.md:230-242`). Android pinning'i genel olarak önermemekte; gerekiyorsa sahip olunan backup key'ler ve kısa expiration istemektedir ([Android TLS rehberi](https://developer.android.com/privacy-and-security/security-ssl?authuser=2&hl=en)). Native Network Security Config SPKI, backup ve expiration modelini destekler ([Android network security config](https://developer.android.com/privacy-and-security/security-config?authuser=2)).

**Senaryo/etki:** Mevcut leaf hash aktive edilirse Let's Encrypt/CA yenilemesinde eski app sürümleri bütün API erişimini kaybeder. Aktive edilmezse dokümante edilen ekstra MITM koruması yoktur; yalnız standart platform TLS/CT/trust-store vardır.

**Remediation:** ADR ile iki seçenekten birini açıkça seçin: (a) standard platform TLS + CT, no pin; veya (b) native/kanıtlanmış SPKI primary+backup+expiry ve ölçülmüş rotation runbook. Mevcut leaf DER implementasyonunu olduğu gibi production'a açmayın. Dokümanı gerçek durumla eşleyin.

### SEC-11 — P2 — KVKK bilgi erişimi/data export akışı repository'de yok

**Kanıt:** `CLAUDE.md:453` `/v1/account/data-export` akışının var olduğunu söyler. Repo-geneli taramada bunun dışında endpoint, repository, use case, UI veya test bulunmadı; `lib/core/constants/api_endpoints.dart:10-22` içinde account/data-export sabiti yoktur. KVKK metni hakları sayar ama pratik kanal yalnız e-postadır (`lib/features/legal/data/sources/kvkk_disclosure_tr.dart:70-93`).

**Senaryo/etki:** Kullanıcı belgede/ekip sözleşmesinde var olduğu varsayılan in-app export'u arar; uygulama talebi başlatamaz, izleyemez veya teslim edemez. Operasyon e-postaya bağlı ve test edilemez kalır.

**Remediation:** Ya gerçek authenticated/pseudonymous export request + status + secure download akışını uçtan uca uygulayın ya da `CLAUDE.md` iddiasını kaldırıp gerçek e-posta başvuru SLA/runbook'unu belgeleyin. Export'un başka kullanıcının device ID'sine erişemediğini kontrat testleriyle kanıtlayın.

### SEC-12 — P2 — Sentry bootstrap Future'ı await edilmiyor; hata yakalama yorumu kullanılan SDK ile yanlış

**Kanıt:** `main()` senkrondur ve `SentryFlutter.init` Future'ı await edilmez (`lib/main.dart:14-34,109`). Analyzer `discarded_futures` için warning tanımlar (`analysis_options.yaml:14-20`). Yorum Sentry'nin appRunner'ı her zaman `runZonedGuarded` içinde çalıştırdığını söyler (`lib/main.dart:19-33`); Sentry resmî kullanımında `Future<void> main() async { await SentryFlutter.init(...) }` vardır ve Flutter 3.3+ için `PlatformDispatcher.onError`, eski sürümler için `runZonedGuarded` kullanıldığı açıklanır ([Sentry Flutter kullanımı](https://pub.dev/packages/sentry_flutter)).

**Senaryo/etki:** SDK init/option hatası Future üzerinde tamamlanır fakat entrypoint tarafından sahiplenilmez; startup sırası ve test davranışı belirsizleşir. Yanlış yorum gelecekte ikinci error zone veya yanlış duplicate-capture düzeltmesine yol açar.

**Remediation:** `Future<void> main() async` yapıp init'i await edin; `SentryWidgetsFlutterBinding.ensureInitialized()` gereksinimini kullanılan 8.14.2/upgrade hedefi için doğrulayın. Init failure ve pre-`runApp` exception için bootstrap test/smoke ekleyin; yorumu SDK sürümüyle eşleyin.

### SEC-13 — P2 — Error semantics: Bilinmeyen bütün 403 yanıtları paywall kabul ediliyor

**Kanıt:** Tanınan RFC-7807 `feature-disabled` doğru map edilir (`lib/core/error/dio_error_mapper.dart:61-79`), fakat type yok/tanınmıyorsa her 403 `FeatureDisabledError` olur (`lib/core/error/dio_error_mapper.dart:92-106`). Yorum gelecekte farklı 403 eklenirse yanlış davranacağını zaten kabul eder (`lib/core/error/dio_error_mapper.dart:98-101`). Benzer biçimde bütün fallback 404'ler `PriceNotFoundError` olur (`lib/core/error/dio_error_mapper.dart:92-94`).

**Senaryo/etki:** Backend account suspended, authorization denied, WAF veya güvenlik policy 403 döndürür. İstemci bunu upgrade/paywall olarak gösterir; security/auth olayı raporlanmayabilir ve kullanıcı yanlış yönlendirilir. Gelecekte account endpoint 404'ü fiyat hatasına çevrilebilir.

**Remediation:** Yalnız exact RFC-7807 type'ı paywall yapın. Unknown 401/403 için ayrı `Authentication/AuthorizationError`, unknown 404 için endpoint-neutral `NotFoundError`, diğerleri için `ServerError` kullanın. Gateway'in body yutması gerekiyorsa güvenilir header/error code sözleşmesi tanımlayın; tüm endpoint sınıflarıyla contract test yapın.

### SEC-14 — P2 — Dependency vulnerability kontrolü zamanlanmıyor ve merge/release'i durdurmuyor

**Kanıt:** `.github/dependabot.yml:1-5` Pub paketlerinin OSV ile “haftalık” tarandığını söyler; `.github/workflows/ci.yml:13-17` yalnız push/PR tetikler, `schedule` yoktur. OSV adımı `continue-on-error:true` olduğu için bulgu merge/release'i durdurmaz (`.github/workflows/ci.yml:131-161`) ve release workflow OSV sonucunu kontrol etmez. iOS update entry'si `package-ecosystem: bundler`, `/ios` kullanır (`.github/dependabot.yml:51-68`), ancak repoda `Gemfile` yoktur; CocoaPods `Podfile.lock` update'i sağlamaz. `flutter_secure_storage` 9.2.4 (`pubspec.lock:238-245`) güncel 10.x güvenlik/migration hattının gerisindedir; v10 eski Jetpack Security `encryptedSharedPreferences` yolundan RSA-OAEP + AES-GCM ve migration araçlarına geçişi açıklar ([paket changelog](https://pub.dev/packages/flutter_secure_storage/changelog), [güncel paket rehberi](https://pub.dev/packages/flutter_secure_storage)). `sentry_flutter` 8.14.2 de major geridedir (`pubspec.lock:624-631`).

**Senaryo/etki:** Repo haftalarca değişmezken yeni CVE yayınlanır; workflow tetiklenmez. Sonraki release eski lockfile'ı kullanır ve OSV job daha önce fail etse bile release'e etkisi olmaz. CocoaPods bağımlılıkları otomatik izlenmiyormuş gibi görünür.

**Remediation:** Haftalık `schedule` + manual dispatch ekleyin; high/critical exploitable bulguları fail-closed yapın ve release guard'da son başarılı taramanın SHA/tazeliğini doğrulayın. CocoaPods için desteklenen update bot/renovate stratejisi kurun. Secure-storage major migration'ını device-ID continuity, rollback ve bozuk ciphertext testleriyle planlayın; körlemesine major bump yapmayın.

**Temiz kontrol:** Bu review'de 116 Pub paketinde OSV eşleşmesi bulunmadı; `pubspec.lock` hosted package checksum'larını içeriyor.

### SEC-15 — P2 — Secret/artifact ignore kapsamı eksik; canlı deploy endpoint'i commit edilmiş

**Kanıt:** `.gitignore:15-22` Android keystore/jks/key.properties ve `.gitignore:63-66` `.env` dosyalarını kapsar. Ancak `*.p8`, `*.p12`, `*.mobileprovision`, özel `.pem/.key`, service-account JSON, dart-define JSON, `.ipa` ve `.aab` için genel ignore yoktur (`.gitignore:24-41`). `.claude/skills/device-deploy/SKILL.md:14,37,44` aktif-looking tüneli ve fiziksel cihaz identifier'ını commit eder; bu `CLAUDE.md:428-432` kuralına aykırıdır.

**Senaryo/etki:** Maintainer lokal signing/export artifact'ini veya App Store `.p8` key'ini yanlışlıkla `git add` eder. Tünel bilgisi commit history'den keşfedilir, eski endpoint deploy edilir veya test cihazı bilgisi gereksiz ifşa olur.

**Remediation:** Ignore kalıplarını genişletin; pre-commit/CI secret scanner (ör. gitleaks/trufflehog politikası) ekleyin ve history taraması yapın. Tünel/device ID'yi kişisel/local config'e taşıyın. Signing artifact'leri ephemeral temp/keychain içinde üretip job sonunda açıkça temizleyin.

**Temiz kontrol:** Tracked dosyalarda yaygın private-key/token imzası veya signing artifact uzantısı bulunmadı; `android/key.properties.example` placeholder'dır.

### SEC-16 — P2 — Release tekrarlanabilirlik, idempotency ve provenance eksikleri

**Kanıt:** Build number `github.run_number`'dır (`.github/workflows/release.yml:103-105`, `CLAUDE.md:289-295`). Aynı workflow run'ının re-run'ı aynı build number'ı kullanır; store'a kısmen yüklenmiş bir build sonrası retry duplicate sürüme çarpabilir. Tag yalnız ancestor kontrolünden geçer ve lightweight tag kabul edilir (`.github/workflows/release.yml:85-94,138-150`). AAB/IPA 90 gün artifact olarak ve GitHub Release'e yüklenir (`.github/workflows/release.yml:319-324,438-443,586-625`), ancak checksum, SBOM, build attestation veya artifact provenance yoktur. App Store Connect PATCH/POST curl çağrıları `--fail-with-body` kullanmaz (`.github/workflows/release.yml:550-582`), bu yüzden 4xx/5xx exit 0 olup “notlar eklendi” yazabilir (`.github/workflows/release.yml:584`). Hata mesajı 40 deneme yerine 30 der (`.github/workflows/release.yml:523-546`).

**Senaryo/etki:** Android upload başarılı, iOS metadata veya GitHub Release başarısız olur; re-run aynı version/build numarasıyla deterministik toparlanamaz. Kullanıcı/maintainer release asset'inin hangi SHA ve dependency setinden üretildiğini doğrulayamaz. Store API 401/422 dönse bile pipeline başarılı metadata mesajı verir.

**Remediation:** Monotonik ve retry-safe build number registry kullanın; store upload'larını “exists/already uploaded” durumunda idempotent reconcile edin. Annotated/signed tag, source SHA, lockfile hash, toolchain sürümleri, SBOM, checksums ve GitHub artifact attestation yayımlayın. Curl için `--fail-with-body --retry` ve response status/body validation ekleyin; durum mesajlarını düzeltin.

### SEC-17 — P2 — iOS release plist'i local cleartext istisnasını production'a taşıyor

**Kanıt:** Tek `ios/Runner/Info.plist` bütün build config'lerinde `NSAllowsLocalNetworking=true` ve localhost insecure HTTP exception taşır (`ios/Runner/Info.plist:48-80`). Android bunu doğru biçimde debug-only resource overlay ile ayırır (`android/app/src/main/res/xml/network_security_config.xml:14-19`, `android/app/src/debug/res/xml/network_security_config.xml:14-27`). Dart validator release HTTP'yi reddeder, fakat native/plugin URLSession trafiği bu validator'dan geçmek zorunda değildir. Apple `NSAllowsLocalNetworking`'in local/unqualified kaynaklara ATS istisnası sağladığını tanımlar ([Apple Info.plist key](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking)).

**Senaryo/etki:** Gelecekte native plugin veya yanlış URL path'i local HTTP endpoint'e erişir; release build'de beklenmedik cleartext yüzeyi açık kalır. Mevcut Dart API çağrısı açısından doğrudan exploit gösterilmemiştir.

**Remediation:** Debug ve Release Info.plist/xcconfig varyantlarını ayırın; release'den `NSAllowsLocalNetworking` ve localhost exception'ını kaldırın. Built IPA içindeki effective plist'i CI'da lint/assert edin.

### SEC-18 — P2 — Native/security release test boşluğu

**Kanıt:** iOS native test tek skipped placeholder'dır (`ios/RunnerTests/RunnerTests.swift:5-9`). Repository'de Android instrumentation test yoktur. Unit testler validator/pinning/device ID/retry/scrubber'ı parça bazında kapsasa da gerçek platform Keychain/Keystore erişilebilirlik ve migration'ı, uninstall/reinstall identity davranışı, ATS/network-security effective config, signing/export entitlements, Sentry envelope/symbolication ve signed release artifact startup'ı kapsamaz. Release workflow da store upload öncesi böyle bir smoke çalıştırmaz (`.github/workflows/release.yml:214-451`).

**Senaryo/etki:** Unit testler yeşilken iOS Keychain accessibility/delete semantiği, Android secure-storage migration, effective ATS, provisioning veya release-only define hatası yalnız mağaza/gerçek cihazda ortaya çıkar.

**Remediation:** En az bir Android/iOS release smoke matrisi, native config assertions, secure-storage upgrade/reinstall fixtures, account deletion end-to-end backend test double ve Sentry scrubbed envelope snapshot ekleyin. Signed artifact'i store upload öncesi boot/API health testinden geçirin.

## 5. P3 bulgular

### SEC-19 — P3 — Retry/cancellation davranışı eksik

`RetryInterceptor` yalnız connection/receive/connect timeout ve 502/503/504 için GET/HEAD retry yapar (`lib/core/network/retry_interceptor.dart:33-43,55-74`). İdempotent method sınırı olumlu kontroldür. Ancak `sendTimeout` mapper'da bağlantı hatası sayıldığı halde retry edilmez (`lib/core/error/dio_error_mapper.dart:31-40`), `Retry-After` dikkate alınmaz ve backoff delay CancelToken/lifecycle cancellation ile kesilemez (`lib/core/network/retry_interceptor.dart:77-100`). `cancel` gelecekte kullanılırsa `ServerError`'a düşer (`lib/core/error/dio_error_mapper.dart:49-55`). Send-timeout, cancellation ve Retry-After testleri ekleyin; delay'i injectable/cancellable yapın.

### SEC-20 — P3 — Account endpoint merkezi sabit sözleşmesini ihlal ediyor

`AccountDataRepositoryImpl` literal `'/v1/account'` kullanır (`lib/features/account/data/repositories/account_data_repository_impl.dart:89-93`); merkezi `ApiEndpoints` içinde account/data-export sabiti yoktur (`lib/core/constants/api_endpoints.dart:10-22`). Bu, endpoint'lerin tek yerde tutulmasını isteyen `CLAUDE.md:383-400` kuralına aykırıdır ve deletion/export drift'ini kolaylaştırır. Endpoint'i merkezi sabite taşıyın, account API contract testini ekleyin ve dokümandaki yanlış `core/network/api_endpoints.dart` yolunu gerçek `core/constants` yolu ile düzeltin.

### SEC-21 — P3 — Review otomasyonu gerçek branch ve doküman kapsamıyla eşleşmiyor

CodeRabbit yalnız `master` base branch'ini auto-review eder (`.coderabbit.yaml:9-14`), gerçek branch'ler `main` ve `development`tır (`.github/workflows/ci.yml:13-17`). Hem CodeRabbit hem Sourcery `docs/**` dosyalarını dışlar (`.coderabbit.yaml:15-21`, `.sourcery.yaml:9-14`); oysa release/KVKK güvenlik sözleşmelerinin önemli bölümü dokümandadır. Branch listesini düzeltin, legal/release docs için ayrı uzman review instruction ekleyin ve bot review'un required human review yerine geçmediğini ruleset'te açıkça koruyun.

### SEC-22 — P3 — Debug cleartext allowlist'leri platformlar arasında tutarsız

Dart validator debug HTTP için ngrok/cloudflare suffix'lerine izin verir (`lib/core/network/api_base_url_validator.dart:25-30,84-94`), Android debug Network Security Config ise yalnız localhost/127.0.0.1/10.0.2.2 cleartext'e izin verir (`android/app/src/debug/res/xml/network_security_config.xml:20-27`). Tüneller normalde HTTPS olduğundan şu an düşük etkili, fakat HTTP tünel değeri validator'dan geçip platformda sessizce kırılabilir. Tek kaynaklı allowlist veya açıkça “tunnel HTTPS-only” kuralı ve cross-platform config testi kullanın.

## 6. Olumlu kontroller / temiz sonuçlar

- Android production cleartext'i kapatır ve yalnız system trust anchor kullanır (`android/app/src/main/res/xml/network_security_config.xml:14-19`). User-installed CA'yı production'a ekleyen debug override yoktur.
- Android `allowBackup=false` ve hem legacy hem Android 12+ backup/device-transfer kuralları exclude-all'dır (`android/app/src/main/AndroidManifest.xml:24-31`, `android/app/src/main/res/xml/backup_rules.xml:13-19`, `android/app/src/main/res/xml/data_extraction_rules.xml:14-28`). Secure storage restore/cipher mismatch riskine karşı doğru temel kontroldür.
- Android main manifest'te yalnız `INTERNET` izni vardır; launcher activity'nin exported olması intent-filter gereğidir ve deep-link/share-target surface'i yoktur (`android/app/src/main/AndroidManifest.xml:1-2,41-69`).
- iOS fotoğraf izni read+write yerine add-only'dir (`ios/Runner/Info.plist:81-94`); repo app entitlement dosyası veya keychain sharing access group içermemektedir.
- Secure storage iOS'ta this-device-only/non-synchronizable, Android'de encrypted shared preferences olarak merkezileştirilmiştir (`lib/core/storage/secure_storage_factory.dart:18-34`). Bu uninstall garantisi vermez, fakat sync/backup sınırını daraltır.
- Device ID ilk çözümlemeyi tekilleştirir, write failure'da session-stable ephemeral ID kullanır ve reset race'i epoch ile önler (`lib/core/network/device_id_interceptor.dart:22-29,50-78`).
- Retry varsayılanı yalnız GET/HEAD'dir; POST hesaplama/senaryo ve DELETE'i körlemesine tekrar ederek çift etki yaratmaz (`lib/core/network/retry_interceptor.dart:39-43,55-64`).
- Sentry screenshot, attachment, view hierarchy, request body/query/cookie, Authorization header ve `SentryUser` alanlarını temizlemek için güçlü savunmalar içerir (`lib/main.dart:47-59`, `lib/core/observability/sentry_pii_scrubber.dart:292-335,409-438`). Bulgular bu mekanizmayı kaldırmayı değil eksik sınırlarını kapatmayı önerir.
- Android release minify/resource shrink ve optimize ProGuard kullanır (`android/app/build.gradle.kts:53-63`). Workflow keystore decode, alias ve iki password'ü fail-closed doğrular (`.github/workflows/release.yml:249-293`).
- Xcode Release dSYM üretir ve manual distribution signing kullanır (`ios/Runner.xcodeproj/project.pbxproj:646-702`); `ios/ExportOptions.plist:9-12` Apple symbol upload ve manual signing'i tanımlar.
- Gradle distribution checksum sabitlenmiştir (`android/gradle/wrapper/gradle-wrapper.properties:3-4`). Tracked wrapper JAR geçerli zip olarak açılmıştır.
- Tag input'u strict regex + environment indirection ile kontrol edilir (`.github/workflows/release.yml:57-76`); kullanıcı kontrollü release notes shell'e doğrudan interpolate edilmez (`.github/workflows/release.yml:326-339,463-476`).
- CI checkout'ları credentials persistence'ı kapatır ve `GITHUB_TOKEN` dış varsayılanı read-only'dir (`.github/workflows/ci.yml:35-37,69-71,147-149,206-208,263-265`).
- Hook `set -euo pipefail` kullanır, Flutter yoksa fail-closed olur ve format/analyze/test çalıştırır (`.githooks/pre-commit:1-57`). Hook bypass edilebilir olduğundan CI/ruleset yerine geçmez.
- Bu review'de tracked private key/token kalıbı ve signing artifact'i bulunmadı; OSV sorgusunda bilinen paket eşleşmesi yoktu.

## 7. Önceliklendirilmiş düzeltme planı

### Store release'ten önce — bloklayıcı

1. GitHub `main` ruleset + production environment required reviewer/protection kurallarını gerçekten oluşturun; exact-SHA CI gate'i release'e bağlayın (SEC-01).
2. Production/staging API origin'lerini ayırın, ngrok production variable'ını kaldırın ve hostname allowlist/preflight koyun (SEC-02, SEC-08, SEC-09).
3. Account deletion protokolünü identity kaybetmeyen, idempotent ve doğrulanabilir modele taşıyın (SEC-03).
4. Hukuk/DPO onaylı KVKK/privacy metinlerini gerçek veri akışına eşleyin; uninstall ve anonymity beyanlarını düzeltin (SEC-04, SEC-11).
5. Sentry DSN + symbol upload + privacy-envelope testini release'e bağlayın; typed context/küçük tutar bypass'larını kapatın (SEC-05, SEC-06).
6. Release Actions'ı immutable SHA'ya pinleyin ve repository Actions allowlist/SHA enforcement'ı açın (SEC-07).

### İlk hardening sprint'i

7. Release URL shell handling, annotated tag enforcement, idempotent retry, checksum/SBOM/attestation ve curl status kontrolünü düzeltin (SEC-09, SEC-16).
8. Sentry bootstrap ve HTTP error semantics'i düzeltip test edin (SEC-12, SEC-13).
9. Scheduled/gating dependency scan ve gerçek CocoaPods update stratejisi kurun; secure-storage migration planı hazırlayın (SEC-14).
10. iOS release ATS istisnasını kaldırıp native release smoke testleri ekleyin (SEC-17, SEC-18).

### Sürekli iyileştirme

11. Retry/cancellation, endpoint merkezi sabitleri, review bot branch/doc kapsamı ve debug allowlist drift'ini kapatın (SEC-19–SEC-22).

## 8. Kabul kriterleri

Bu review alanı aşağıdaki kanıtlar olmadan “production ready” sayılmamalıdır:

- GitHub API'de protected `main`, required checks ve reviewer-protected `production` environment görünür.
- Production ve staging farklı, sahipliği doğrulanmış origin kullanır; release preflight yanlış host'u reddeder.
- Aynı deletion request'in timeout, lost response, 5xx ve retry senaryolarında server kaydı silinir veya kullanıcı retry hakkını korur; device identity premature silinmez.
- Kullanıcıya gösterilen privacy/KVKK metni hukuk onaylıdır ve gerçek network/storage/Sentry akışıyla test edilmiş bir data inventory'ye bağlıdır.
- Sentry canary event'i production-like RC'de ulaşır, sembollenir ve serialized envelope'da device ID/isim, finansal amount/date/asset bulunmaz.
- Release workflow exact approved SHA'yı test/build eder; store upload öncesi iki platform release smoke, OSV policy ve immutable Action enforcement geçer.
- Signed AAB/IPA için source SHA, lock hash, checksum, SBOM/provenance üretilir ve retry edilmiş release deterministik biçimde reconcile edilir.
