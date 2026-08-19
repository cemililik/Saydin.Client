# Kanıtlı bulgular

## Severity tanımı

| Seviye | Anlam |
|---|---|
| P0 | Release blocker; desteklenen platform, veri silme/mahremiyet veya ortak share zinciri kırılıyor |
| P1 | Yüksek etki; marka güveni, payload doğruluğu, kullanıcı iradesi veya erişilebilirlik temel beklentisi karşılanmıyor |
| P2 | Orta etki; kalite, bakım, tutarlılık veya hata kurtarma önemli ölçüde zayıf |
| P3 | Düşük etki; polish veya savunmacı sözleşme açığı |

## Olumlu temel

- Kullanıcı sonuç ekranından tek dokunuşla paylaşmıyor; önce preview, sonra açık CTA vardır (`share_preview_sheet.dart:85-139`).
- `_isSharing` aynı CTA'da ikinci tetiklemeyi engeller (`share_preview_sheet.dart:23-28,121-139`).
- PNG kayıpsız üretilir, `ui.Image` başarı/hata yolunda dispose edilir (`share_card_renderer.dart:65-71,97-106`).
- Kaynak temp dosyası native share dönüşünde silinir; startup'ta age/LRU cleanup vardır (`share_card_renderer.dart:78-94,108-162`).
- Kâr/nötr/zarar renk + ikon + işaret + metinle anlatılır (`financial_outcome_style.dart:14-47`).
- Portföy partial sonucu paylaşmaya izin vermez (`portfolio_page.dart:155-156,477-483`).
- Portföy, ilk altı kalemi ve “+N” özetini kullanarak önceki sınırsız liste sorununu çözmüştür (`portfolio_share_card_widget.dart:13,46-47,133-179`).

Bu güçlü noktalar korunmalıdır; aşağıdaki öneriler mevcut sistemi çöpe atmayı değil, ortak ve güvenilir bir ürün yüzeyine dönüştürmeyi amaçlar.

---

## CARD-001 — P0 — Android plugin kopyası silme ve retention sözleşmesinden kaçıyor

**Kanıt**

- Uygulama kendi temp dosyasını `finally` içinde siler (`lib/core/utils/share_card_renderer.dart:72-93`).
- Startup cleanup yalnız temp root'taki `File` tipinde `saydin_share_*.png` girdilerini işler; directory'leri atlar (`share_card_renderer.dart:121-160`).
- Hesap silme cleanup'ı da aynı şekilde yalnız temp root `File`'larını tarar (`lib/features/account/data/repositories/account_data_repository_impl.dart:104-130`).
- Pinli `share_plus 10.1.4`, Android'de her kaynak dosyayı `<cacheDir>/share_plus/` altına kopyalar (`~/.pub-cache/hosted/pub.dev/share_plus-10.1.4/android/src/main/kotlin/dev/fluttercommunity/plus/share/Share.kt:28-30,95-97,179-189,235-252`). Klasörü ancak sonraki share başlangıcında temizler.
- Hesap silme testi yalnız root'ta `saydin_share_result.png` fixture'ı üretir (`test/features/account/data/repositories/account_data_repository_impl_test.dart:186-208`).
- Legal envanter, share kapanışı/startup/account deletion ile cache'in temizlendiğini iddia eder (`docs/legal/legal-release-signoff.md:53,56`); nested plugin kopyası bu iddianın dışında kalır.

**Etki**

Son Android paylaşımının finansal PNG'si kaynak dosya silinse ve kullanıcı hesap silme akışını tamamlamış olsa bile app cache'inde sonraki share veya OS eviction'a kadar kalabilir. Bu, veri minimizasyonu ve hesap silme kanıtı açısından blocker'dır.

**Öneri**

Native dağıtımı injectable `ShareGateway` arkasına alın. Android plugin cache konumu canonical path ile doğrulanarak yalnız beklenen `${cacheDir}/share_plus` hedefi için lifecycle-resume/startup/account-wipe cleanup tasarlansın. Symlink/reparse benzeri path sapmaları ve delete hataları fail-visible olsun. Gerçek cihazda paylaşım tamamlandıktan sonra hedef uygulamanın dosyayı ne zaman tükettiği doğrulanmadan agresif immediate delete varsayımı yapılmasın; retention sözleşmesi ölçülen davranışa göre yazılsın.

**Kabul kanıtı:** Nested fixture testi, account wipe testi, force-quit testi, Android gerçek cihaz share smoke ve düzeltilmiş legal inventory.

## CARD-002 — P0 — iPad share popover anchor eksik

**Kanıt**

- `Share.shareXFiles` çağrısı yalnız files ve text gönderir; `sharePositionOrigin` yoktur (`lib/core/utils/share_card_renderer.dart:78-81`).
- iOS target device family `1,2` ile iPhone ve iPad'i destekler (`ios/Runner.xcodeproj/project.pbxproj:482,612,665`).
- Kullanılan plugin'in kendi README'si iPad'de origin'i zorunlu sayar ve yokluğunda crash veya yanıtsız UI riski belirtir (`~/.pub-cache/hosted/pub.dev/share_plus-10.1.4/README.md:179-207`).

**Etki**

Ortak renderer nedeniyle beş kartın tamamı desteklenen iPad'de son adımda kırılabilir.

**Öneri**

CTA'nın gerçek `RenderBox` global rect'i common sheet'te çıkarılmalı ve gateway'e `Rect sharePositionOrigin` olarak zorunlu verilmelidir. Rect finite, non-empty ve görünür yüzey içinde değilse native çağrı yapılmamalıdır.

**Kabul kanıtı:** iPad portrait, landscape ve Split View; source CTA scroll/resize sonrası; success/dismiss/error gerçek cihaz smoke.

## CARD-003 — P1 — Onaylı kimlik paylaşım kartlarında kullanılmıyor

**Kanıt**

- Resmî palette navy `#0B1D34`, teal `#2CB1B8`, off-white `#F5F6F7`'dir (`assets/branding/README.md:15`).
- Runtime ana renk `#1565C0` Material blue'dur (`lib/core/constants/app_colors.dart:6`); tema bu seed'den türetilir (`lib/core/theme/app_theme.dart:8-17`).
- Beş kart üst çizgi/wordmark/domain için bu maviyi kullanır; örnek `share_card_widget.dart:55,62-68,279-285`.
- `AppBranding.wordmark` yalnız `'saydın'` string'idir (`app_branding.dart:10-14`); header varsayılan sistem fontuyla `Text` çizer.
- Marka master'ları runtime'a paketlenmez (`assets/branding/README.md:5-6`); `pubspec.yaml:64-66` altında asset/font yoktur.

**Etki**

Kullanıcı native ikon/splash'te özgün “Zaman İzi” sembolünü, paylaşım kartında ise generic mavi finans dashboard'u görür. Paylaşılan artifact marka tanınabilirliği ve güven üretmez.

**Öneri**

Brand ekibinden runtime için optimize edilmiş standalone symbol ve kilitli horizontal wordmark alın; açık/koyu zeminde safe-area ve minimum boyutları tanımlansın. `BrandMark` primitive'i onboarding/app bar/share header'da tek kaynak olsun. Product runtime palette, approved brand tokens'tan türesin; teal vurgu, navy ana metin/zemin rolünde kullanılmalı, teal küçük metin rengi olarak kullanılmamalıdır.

## CARD-004 — P1 — Ortak tasarım sistemi yerine beş kopya template var

**Kanıt**

- Beş kart yaklaşık 1.859 LOC'dur.
- Header, footer, value pair, outcome hero ve inflation paneli kopyalanmıştır.
- Somut drift: What-if/Reverse/DCA inflation için iki alanı AND ile gate eder (`share_card_widget.dart:42-44`; `reverse_share_card_widget.dart:33-35`; `dca_share_card_widget.dart:43-45`); Portföy yalnız real alana göre açılır ve cumulative null'u `%0` yapar (`portfolio_share_card_widget.dart:41-45,333-334`); Comparison inflation'ı hiç göstermez (`comparison_share_card_widget.dart:117-169`).
- Comparison ve Portfolio, core `DurationLabel` yerine What-if presentation widget'ının static helper'ına bağımlıdır (`comparison_share_card_widget.dart:8,94-98`; `portfolio_share_card_widget.dart:9,106-110`). DCA core helper'ı doğrudan kullanır.

**Etki**

Her görsel iyileştirme beş dosyada elle tekrarlanır. Tasarım ve finansal veri sözleşmesi birlikte drift eder; bu yalnız bakım sorunu değil, paylaşılan verinin farklılaşmasıdır.

**Öneri**

`core/share` altında tek `ShareCardFrame`, `ShareHeader`, `ValuePair`, `OutcomeHero`, `InflationPanel`, `DetailModule`, `ShareFooter` oluşturun. Feature katmanı widget değil immutable `ShareCardViewModel` üretmeli. Kartlar yalnız variant-specific module kompozisyonu yapmalıdır.

## CARD-005 — P1 — Canonical artboard ve en-boy oranı yok

**Kanıt**

- Her kart yalnız 540 logical px genişlik verir, height intrinsic'tir (`share_card_widget.dart:46-49`; diğer dört kartta aynı pattern).
- Renderer yalnız genişliği 1080 px'e ölçekler (`share_card_renderer.dart:38,61-66`).
- Mevcut maksimum Portföy golden'ı 540×690'dır; gerçek renderer karşılığı 1080×1380 olur.
- Inflation, comparison row sayısı, portfolio item sayısı ve content wrap yüksekliği değiştirir.

**Etki**

Kartlar aile gibi görünse de kadraj/ritim birliği yoktur; sosyal thumbnail veya target app crop davranışı test edilemez. Ana mesaj bazı varyantlarda üstte, Portföy'de ise yoğun listenin altında kalır.

**Öneri**

Product bir canonical feed artboard seçmeli; bu review `1080×1350` 4:5'i iç standart olarak önerir. Square/story gerekliyse ayrı preset olmalı. Sabit safe-zone içinde içerik özetlenmeli; renderer exact pixel dimension assertion'ı üretmelidir.

## CARD-006 — P1 — Önizleme final payload'ı göstermiyor

**Kanıt**

- Sheet yalnız `cardWidget`ı render eder (`lib/core/widgets/share_preview_sheet.dart:91-111`).
- `shareText` preview'da görünmez.
- Renderer, kullanıcıya gösterilmeden `(shareText ?? shareDefaultText) + shareCta` oluşturur (`share_card_renderer.dart:57-60`).
- Caption'lar asset/tutar/yüzde gibi finansal veri taşır (`app_tr.arb:285-309,373,393`).
- Privacy metni kullanıcıya preview ve recipient'ı kontrol etmesini söyler (`privacy_policy_tr.dart:71-75`).

**Etki**

Kullanıcı yalnız görseli onayladığını düşünürken görünmeyen finansal caption ve promosyon CTA da paylaşılır. Tutarı gizleme, caption'ı düzeltme veya CTA'yı kaldırma seçeneği yoktur.

**Öneri**

Tek `SharePayload` içinde image view model + final caption + privacy seçenekleri birlikte üretilsin. Sheet tam caption/CTA'yı göstersin; “Tutarları gizle”, “Dağılımı gizle”, caption düzenle, CTA on/off, metni kopyala seçenekleri sunulsun. Final native çağrı preview'da görülen immutable payload'ı kullanmalıdır.

## CARD-007 — P1 — Share kill-switch yalnız DCA'da çalışıyor

**Kanıt**

- Global alan `AppFeatureFlags.share` olarak tanımlıdır (`lib/features/config/domain/entities/app_config.dart:76-90`).
- Production tüketimi yalnız DCA'dadır (`dca_page.dart:414-446`).
- Normal/reverse What-if (`what_if_page.dart:266-317`), Comparison (`comparison_page.dart:451-465`) ve Portfolio (`portfolio_page.dart:477-490`) flag'i kontrol etmez.
- Senaryolar replay sonrası aynı sayfalara döndüğü için bypass replay'de de vardır.

**Etki**

Incident, compliance veya rollout sırasında global share kapatma kararı dört sonuç ailesinde uygulanmaz.

**Öneri**

`SharePolicy.canShare(config, result)` tek kaynak olsun. UI görünürlüğü, preview açılışı ve native gateway çağrısı aynı policy'yi fail-closed uygulasın. Flag preview açıkken kapanırsa native çağrı durmalıdır.

## CARD-008 — P1 — Sonuç/PNG/caption aynı finansal projection değil

**Kanıt**

- What-if/Reverse entity gerçek işlem günleri ve `inflationDataAsOf` taşır (`what_if_result.dart:45-53`; `reverse_what_if_result.dart:25-30`). Ana sonuç kartı ayarlanmış tarih notunu ve CPI tarihini gösterir (`result_card.dart:245-261,308-339`; reverse eşleniği).
- Share kartı yalnız request `buyDate` ve tek tarih aralığı basar; caveat/as-of yoktur (`share_card_widget.dart:106-124`; reverse `97-115`).
- DCA ana kart partial inflation alanlarını ayrı ayrı gösterebilir (`dca_result_card.dart:209-282`); share kart ikisi birlikte değilse tüm bölümü düşürür (`dca_share_card_widget.dart:43-45,292-296`).
- Portföy geçerli biçimde real dolu/cumulative null üretebilir (`calculate_portfolio.dart:88-125`); share kart null cumulative'i `%0` basar (`portfolio_share_card_widget.dart:333-334`).
- Comparison sonuç satırı reel getiriyi gösterebilir (`comparison_result_card.dart:146-156`); share kart yalnız nominal yüzdeyi taşır (`comparison_share_card_widget.dart:117-169`).

**Etki**

Kullanıcının ekranda gördüğü finansal bağlam paylaşımda kaybolur; hatta hesaplanmamış inflation `%0` olarak üretilebilir. Bu güven ve doğruluk sorunudur.

**Öneri**

UI/save/share/caption tek typed projection'dan türesin. `InflationMetrics` alanları bağımsız nullable/availability state taşısın; finansal null hiçbir yerde `?? 0` ile sunulmasın. Requested/actual date, calculation as-of, CPI as-of, nominal/reel ayrımı ve simülasyon etiketi payload sözleşmesinde zorunlu olsun.

## CARD-009 — P1 — Düşük görüş kullanıcıları preview'ı güvenle doğrulayamıyor

**Kanıt**

- 540 dp kart küçük cihazda `FittedBox.fitWidth` ile küçülür (`share_preview_sheet.dart:91-111`). 320 dp içerikte ölçek kabaca yarıya iner.
- Kart ağacı `MediaQuery.withClampedTextScaling(maxScaleFactor: 1)` ile font tercihini yok sayar (`share_preview_sheet.dart:102-110`).
- Kartlarda 10–13 px yardımcı metinler vardır; DCA mini-label 10 px'tir (`dca_share_card_widget.dart:334-350`).
- Zoom/pan ve sistem text scale ile akan eşdeğer özet yoktur.
- Mevcut %200 testi yalnız overflow olmadığını assert eder (`portfolio_share_card_widget_test.dart:47-87`).

**Etki**

Artifact teknik olarak taşmasa da preview 5–7 dp eşdeğeri metne düşebilir. Kullanıcı paylaşacağı finansal içeriği okuyamaz.

**Öneri**

Capture artboard text scale'i sabit kalabilir; karar verme preview'ı ayrı olmalıdır. Kart `InteractiveViewer` ile zoom/pan almalı, altında sistem text scale ile responsive “paylaşılacak özet” gösterilmelidir. Semantics bu özeti tek, anlamlı yapı olarak sunmalıdır.

## CARD-010 — P1 — Küçük yardımcı metinlerin kontrastı AA altında

**Kanıt**

Kartlarda `Colors.grey.shade500` (`#9E9E9E`) beyaz ve `#F5F5F5` yüzeylerde tarih, label ve footer için tekrar kullanılır; örnek `share_card_widget.dart:122-125,146-151,271-277`, Comparison `109-112,185-191`, DCA `123-127,345-350`. Beyaz üzerindeki oran yaklaşık 2.68:1, off-white üzerinde yaklaşık 2.46:1'dir. Küçük normal metin için 4.5:1 hedefini karşılamaz.

**Etki**

Paylaşılan görsel platform sıkıştırması/ölçeklemesi sonrası daha da zor okunur; tarih ve bağlam bilgisi görsel hiyerarşide silinir.

**Öneri**

Share-specific semantic text tokens tanımlayın; small text minimum 4.5:1, büyük metin minimum 3:1 olsun. Teal'i küçük metinde değil vurgu/shape olarak kullanın; navy ve koyu neutral metin rolünü taşısın. Token contrast testi CI'a eklenmelidir.

## CARD-011 — P1 — Uzun içerik ve büyük finansal değerler korunmuyor

**Kanıt**

- What-if/Reverse/DCA asset adlarında genel `maxLines/overflow` yoktur.
- Initial/final değerler ve 44 px yüzde Row içinde `FittedBox(scaleDown)` olmadan çizilir (`share_card_widget.dart:140-195,225-250`; reverse `130-186,215-240`; DCA `142-200,229-257`; Portfolio `194-253,279-305`).
- DCA üç kolon value alanları sınırsızdır (`dca_share_card_widget.dart:342-362`).
- Comparison asset adında tek satır/ellipsis yoktur (`comparison_share_card_widget.dart:150-169`).
- Yüzde response parser'ı finite/range validation göstermiyor (`what_if_response_model.dart:62-73`).

**Etki**

Uzun API adı, büyük tutar, pseudo-l10n veya ekstrem yüzde artifact'te clip/overlap yaratabilir; renderer layout overflow'unu typed share hatasına dönüştürmez.

**Öneri**

Ortak `ResponsiveFinancialValue` primitive'i; max lines, ellipsis, `FittedBox(scaleDown)`, tabular numerals ve ürün onaylı compact notation kullanmalı. Domain/response sınırında finite ve kabul edilebilir display range doğrulanmalıdır.

## CARD-012 — P1 — Share hazırlanırken route kapatılsa native sheet sonradan açılabilir

**Kanıt**

- Bütün modal çağrıları default `isDismissible:true` ve `enableDrag:true` kullanır.
- `_isSharing` yalnız CTA'yı kapatır (`share_preview_sheet.dart:23-45,121-139`).
- `PopScope`, cancel token veya generation guard yoktur.

**Etki**

Kullanıcı back/barrier/swipe ile preview'dan çıktığını düşünürken devam eden capture native share sheet'i açabilir.

**Öneri**

Paylaşım state machine'i cancel-aware olmalı. Route kapanınca token invalid edilir ve native gateway başlamadan önce tekrar kontrol edilir. Tek tap tek invocation üretmeli; preview kapandıktan sonra platform sheet açılamamalıdır.

## CARD-013 — P2 — Native share tek çıkış, hata mesajı tek tip ve recovery yok

**Kanıt**

- Yalnız `share_plus` ile native share vardır (`pubspec.yaml:46-48`; `share_card_renderer.dart:78-81`).
- Clipboard veya explicit save-image fallback'i yoktur.
- `ShareResult` dönüşü atılır; dismissed/unavailable ayrımı yapılmaz.
- Render, storage ve platform hataları aynı `shareError` metnine düşer (`share_preview_sheet.dart:35-55`; `app_tr.arb:152`).
- Catch bloğunda önce `await ErrorReporter.report`, sonra snackbar vardır (`share_preview_sheet.dart:35-42`); reporter çağrısı fırlarsa kullanıcı feedback'i gelmez (`error_reporter.dart:21-44`).

**Etki**

Native hedef yoksa veya target image+text'i reddederse kullanıcı çıkmazda kalır; kart üretilmiş olsa bile “kart oluşturulamadı” denir.

**Öneri**

Render ve distribution ayrılmalı. PNG hazır olduğunda “Paylaş / Görseli kaydet / Metni kopyala” eylemleri verilmeli. Typed errors: render, storage, shareUnavailable, permissionDenied. Feedback telemetriden önce ve ondan bağımsız gösterilmeli; Retry/Copy/Save aksiyonu içermelidir.

## CARD-014 — P2 — Caption dili simülasyonu gerçekleşmiş işlem gibi sunabiliyor

**Kanıt**

- DCA eylemi “Simüle Et” iken caption “N alım yaptım” der (`app_tr.arb:362,373`).
- Portfolio caption “Portföyüm … getiri sağladı” der (`app_tr.arb:301`).
- Normal TR What-if caption explicit geçmiş sell date olsa bile sabit “bugün” kullanır (`app_tr.arb:285`); çağrı end date parametresi vermez (`what_if_page.dart:298-305`).
- Ekrandaki yaklaşık fiyat/komisyon/kur disclaimer'ı (`app_tr.arb:101`) share artifact/caption'da yoktur.

**Etki**

Hipotetik hesap gerçek yatırım performansı gibi algılanabilir; tarihsel bitişe “bugün” denebilir.

**Öneri**

Caption açıkça “simülasyona göre” dili kullanmalı. Open-ended ve explicit end-date için ayrı l10n branch'i olmalı. Product/Legal onaylı kısa disclaimer ve calculation date payload'a bağlanmalıdır.

## CARD-015 — P2 — Semantics/focus/motion sözleşmesi ve testleri eksik

**Kanıt**

- Preview başlığı `Semantics(header:true)` değildir; explicit focus request/restore yoktur (`share_preview_sheet.dart:85-88`).
- 40×4 drag handle dekoratiftir; etiketli Close butonu yoktur (`share_preview_sheet.dart:74-83`).
- Busy/error için explicit `liveRegion` yoktur; error snackbar action'sızdır (`share_preview_sheet.dart:121-139,48-55`).
- Kart çok sayıda raw `Text` semantics node'u üretir; tek anlamlı share summary yoktur.
- Reduced-motion policy okunmaz.
- SemanticsTester veya keyboard/VoiceOver/TalkBack testi yoktur.

**Etki**

Ekran okuyucu ve klavye kullanıcıları sheet giriş/çıkışını, busy durumunu ve paylaşım özetini güvenilir biçimde yönetemez.

**Öneri**

Heading semantics, labelled Close, deterministic focus order, focus restore, live busy/error announcement ve reduced-motion davranışı eklenmeli. Capture görseli `ExcludeSemantics` altında tutulup erişilebilir summary ayrı sunulmalıdır.

## CARD-016 — P2 — Görsel kalite ve deterministik typography korunmuyor

**Kanıt**

- Bundled font yoktur (`pubspec.yaml:64-66`).
- Comparison platform emoji'leri kullanır (`comparison_share_card_widget.dart:23,127-149`).
- Portföy golden'ı host farkı nedeniyle macOS/Linux için iki ayrı referans seçer (`portfolio_share_card_widget_test.dart:136-145`).
- Diğer dört kartın golden'ı yoktur.

**Etki**

Wordmark, emoji ve metrikler Android/iOS/host arasında değişebilir; premium finansal dil yerine oyunlaştırılmış ve platforma bağlı görünüm doğar.

**Öneri**

Türkçe `ı/İ` ve tabular numeral desteği doğrulanmış, lisanslı font bundle edilmelidir. Emoji yerine brand/numeric rank badge kullanılmalı. Beş variant için aynı fontla deterministik 1080 output goldens üretilmelidir.

## CARD-017 — P3 — What-if preview adapter'ı geçersiz boş state kabul ediyor

**Kanıt**

`ShareCardPreviewSheet` hem `result` hem `cardWidgetOverride` null ise `SizedBox.shrink` üretir (`share_card_preview_sheet.dart:6-25`).

**Etki**

Mevcut çağrılar doğru olsa da ileride boş boundary anlamsız capture/hata üretebilir.

**Öneri**

`.normal(result)` ve `.custom(widget)` gibi sealed/required constructor; exactly-one invariant. Gereksiz ince adapter'ları kaldırın.

## CARD-018 — P3 — iOS native share sheet dili için platform doğrulaması yok

**Kanıt**

Pinli plugin, bazı Apple konfigürasyonlarında `CFBundleAllowMixedLocalizations` + `CFBundleDevelopmentRegion` önerir (`share_plus` README `173-177`). Projede development region/localizations vardır; mixed-localizations key'i yoktur (`ios/Runner/Info.plist:7-23`).

**Etki**

Uygulama içi dil ve sistem share sheet dili bazı kombinasyonlarda ayrışabilir.

**Öneri**

Key ihtiyacını iOS release/profile/debug plist ve TR/EN OS×app language matrisiyle doğrulayın; yalnız gerçek cihaz kanıtından sonra ekleyin.
