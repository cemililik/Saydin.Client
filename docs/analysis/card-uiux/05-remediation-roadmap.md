# Uygulama yol haritası ve kabul kriterleri

## 1. Uygulama stratejisi

Roadmap iki hedefi birlikte korur:

1. Ortak platform/privacy blocker'larını tasarım refactor'ını bekletmeden kapatmak.
2. Beş kartı tek tek yamamak yerine yeni share system'e kontrollü taşımak.

“Logo ekle, rengi değiştir, kartları biraz yuvarlat” yaklaşımı yeterli değildir. Preview payload, finansal projection, platform gateway ve test sistemi çözülmeden yalnız görsel iyileştirme yeni drift üretir.

## 2. Fazlar

### Faz 0 — Release güvenliği

**Amaç:** CARD-001 ve CARD-002 blocker'larını kapatmak.

| İş | Boyut | Bağımlılık | Kabul |
|---|---:|---|---|
| `ShareGateway` seam'i ve iPad `sharePositionOrigin` | M | Yok | Non-empty rect; iPad üç layout smoke |
| Android `share_plus` cache lifecycle spike | M | Gerçek cihaz | Source + plugin kopyası retention ölçüldü |
| Güvenli nested cache cleanup | M | Spike kararı | Startup/resume/account wipe fixture + device test |
| Legal inventory düzeltmesi | S | Ölçülmüş davranış | Kod ve metin aynı retention gerçeğini söyler |
| Renderer/gateway failure unit testleri | M | Gateway seam | Origin, unavailable, exception, dismiss, delete failure |

Bu faz tamamlanmadan paylaşım release-ready sayılmaz.

### Faz 1 — Karar ve asset paketi

**Amaç:** Engineering'in tahmin ederek marka veya legal metin üretmesini engellemek.

| Karar | Çıktı | Sahip |
|---|---|---|
| Canonical artboard | 1080×1350 onayı veya alternatif | Product + Design |
| Runtime brand pack | Symbol + wordmark light/dark, safe-area, checksums | Brand |
| Font | Lisans + font files + weight map | Brand + Legal |
| Share copy | TR/EN simülasyon dili ve kısa disclaimer | Product + Legal |
| Privacy defaults | Amount/distribution/CTA defaults | Product + Privacy |

Asset pipeline, mevcut `assets/branding/README.md` provenance yaklaşımını sürdürmeli; runtime assetler için checksum/boyut/alpha/safe-area testleri eklenmelidir.

### Faz 2 — Payload ve policy çekirdeği

**Amaç:** Sonuç, preview, PNG ve caption'ı tek immutable snapshot'a bağlamak.

| İş | Bulgular | Kabul |
|---|---|---|
| `SharePayload` + typed variant view models | CARD-004, 006, 008 | Final caption renderer içinde değişmez |
| `SharePolicy` | CARD-007 | 5 direct + 4 replay testinde flag false fail-closed |
| Typed `InflationMetrics` | CARD-008 | partial states kaybolmaz, null→0 yok |
| Date/as-of projection | CARD-008, 014 | requested/actual/CPI parity |
| Privacy options | CARD-006 | hide amounts/distribution outputta doğrulanır |
| Caption copy rewrite | CARD-014 | simülasyon/tarih/disclaimer TR/EN testleri |

Bu fazın önemli kuralı: `ShareRenderer` l10n, CTA veya business rule bilmez.

### Faz 3 — Ortak görsel sistem

**Amaç:** Approved kimlikle exact artboard üzerinde tek component family kurmak.

| İş | Bulgular | Kabul |
|---|---|---|
| Brand/type/spacing/share color tokens | CARD-003, 010, 016 | Token kontrast testleri; bundled font |
| `ShareCardFrame` exact canvas | CARD-005 | Decoded PNG exact dimensions |
| `BrandHeader` + `TrustFooter` | CARD-003, 014 | Gerçek asset; disclaimer/domain |
| `ResponsiveFinancialValue` | CARD-011 | Extreme value min-size/overflow testleri |
| `ValuePair`, `OutcomeHero`, `InflationPanel` | CARD-004, 008 | Tüm partial/outcome states |
| `RankList`, `PortfolioSummary`, `DcaSummary` | CARD-016 ve density bulguları | Emoji/10px stats yok; max content contract |

### Faz 4 — Variant migration

**Önerilen sıra:**

1. Normal What-if — temel frame ve outcome modelini kanıtlar.
2. Reverse What-if — aynı primitive'in farklı hero semantiğini kanıtlar.
3. DCA — detail module ve partial inflation'ı kanıtlar.
4. Comparison — rank component ve nominal/reel mode'u kanıtlar.
5. Portfolio — en yoğun projection ve +N summary'yi en son taşır.

Her migration için:

- Eski ve yeni payload aynı financial fixture ile karşılaştırılır.
- TR/EN full-card golden eklenir.
- Profit/neutral/loss component testi vardır.
- Feature sayfası yeni shared action/policy kullanır.
- Eski widget/adapters ve cross-feature helper bağımlılığı kaldırılır.

Geçişte iki tasarım aynı kullanıcı journey'sinde feature bazlı uzun süre yaşamamalıdır; shared frame hazır olduğunda migration kısa bir pencere içinde tamamlanmalıdır.

### Faz 5 — Preview/editor ve a11y

| İş | Bulgular | Kabul |
|---|---|---|
| Final caption görünümü/edit | CARD-006 | Preview-final equality |
| Zoom/pan + accessible summary | CARD-009 | %200/%300 okunabilirlik |
| Labelled Close, focus, live regions | CARD-015 | VoiceOver/TalkBack/keyboard test |
| Cancel-aware state machine | CARD-012 | Route kapanınca native call sıfır |
| Copy/save fallback + typed errors | CARD-013 | Unavailable/error recoverable |
| Reduced motion | CARD-015 | disableAnimations assertion |

### Faz 6 — QA, rollout ve gözlem

- Full golden matrix ve exact PNG tests.
- iPhone/iPad/Android real-device evidence.
- Android cache/account-wipe inspection.
- Target app compatibility matrix.
- Accessibility kayıtları.
- Share feature flag ile kontrollü rollout.
- Privacy-safe technical metrics: preview opened, share gateway outcome, render failure category; finansal payload yok.

## 3. Önerilen PR dilimleri

| PR | İçerik | Risk yönetimi |
|---|---|---|
| PR-1 | Gateway seam + iPad origin + tests | UI değiştirmez; blocker izole |
| PR-2 | Android cache cleanup + legal contract | Security/privacy review zorunlu |
| PR-3 | SharePayload/Policy/projection | Mevcut kart görünümünü koruyarak data parity |
| PR-4 | Runtime brand/font/tokens + frame | Brand checksum/golden gate |
| PR-5 | What-if + Reverse migration | Primitive doğrulaması |
| PR-6 | DCA + Comparison migration | Partial inflation/ranking |
| PR-7 | Portfolio migration | Max content/golden |
| PR-8 | Preview editor/a11y/fallback | Journey ve native integration |
| PR-9 | Eski kod cleanup + docs/release evidence | Dead code/import/test manifest güncelleme |

## 4. Traceability backlog

| ID | Severity | Ana sahip | Hedef faz |
|---|---|---|---:|
| CARD-001 Android plugin cache | P0 | Mobile + Privacy | 0 |
| CARD-002 iPad origin | P0 | Mobile | 0 |
| CARD-003 Brand disconnect | P1 | Brand + Design + Mobile | 1/3 |
| CARD-004 Kopya templates | P1 | Mobile | 2/3/4 |
| CARD-005 Artboard yok | P1 | Product + Design | 1/3 |
| CARD-006 Final payload görünmüyor | P1 | Product + Mobile + Privacy | 2/5 |
| CARD-007 Kill-switch | P1 | Mobile + Product | 2 |
| CARD-008 Projection parity | P1 | Mobile + Product | 2 |
| CARD-009 Low-vision preview | P1 | Design + Mobile | 5 |
| CARD-010 Kontrast | P1 | Design | 3 |
| CARD-011 Uzun içerik | P1 | Mobile + Design | 3/4 |
| CARD-012 In-flight dismiss | P1 | Mobile | 5 |
| CARD-013 Recovery/fallback | P2 | Mobile + Product | 5 |
| CARD-014 Simülasyon copy | P2 | Product + Legal | 1/2 |
| CARD-015 Semantics/focus/motion | P2 | Mobile + Accessibility | 5 |
| CARD-016 Typography/emoji/goldens | P2 | Brand + Mobile | 1/3/6 |
| CARD-017 Adapter invariant | P3 | Mobile | 4/9 |
| CARD-018 iOS sheet language | P3 | iOS + QA | 6 |

## 5. Merge kabul kriterleri

Bir share PR'ı aşağıdakilerin tamamı olmadan tamamlanmış sayılmaz:

1. Değişen davranışın finding ID'si PR açıklamasındadır.
2. TR ve EN fixture'ları vardır.
3. Financial projection null/zero/date/inflation invariant'larını test eder.
4. İlgili full-card veya component golden günceldir.
5. Exact artboard ve overflow assertion'ı geçer.
6. A11y etkisi varsa Semantics/focus/text-scale testi vardır.
7. Platform davranışı varsa simulator yeterli görülmez; gerekli gerçek-device evidence eklenir.
8. Feature flag false durumunda defense-in-depth test edilir.
9. Finansal payload log/Sentry testinde görünmez.
10. `flutter analyze --fatal-infos`, ilgili tests ve full tracked suite geçer.
11. Doküman ve legal sözleşme kodla aynı gerçeği söyler.

## 6. Program Definition of Done

Paylaşım kartı programı ancak aşağıdaki sonuçların tamamında tamamlanmıştır:

- [ ] Android source ve plugin-owned cache retention/silme davranışı kanıtlı.
- [ ] iPad share anchor ve üç tablet layout gerçek cihazda başarılı.
- [ ] Beş direct ve dört replay journey tek `SharePolicy` kullanıyor.
- [ ] Preview'da final image, full caption, CTA ve recipient notu görünür.
- [ ] Kullanıcı tutar/dağılımı gizleyebilir; preview ve final payload aynıdır.
- [ ] UI/PNG/caption tek immutable snapshot'tan gelir.
- [ ] Actual/requested date, CPI as-of, nominal/reel ve partial inflation parity sağlanır.
- [ ] Resmî marka asset'i, palette ve bundled font kullanılır.
- [ ] Beş variant exact canonical artboard'dadır.
- [ ] Small text AA; zoom ve responsive summary vardır.
- [ ] Long content/extreme value fixture'ları taşmaz.
- [ ] VoiceOver/TalkBack/keyboard/reduced-motion journey kanıtı vardır.
- [ ] Native unavailable/error/dismiss için doğru recovery sunulur.
- [ ] Beş variant TR/EN full-card golden ile korunur.
- [ ] Legal/privacy dokümanı gerçek storage ve recipient davranışını doğru anlatır.
- [ ] Release evidence iOS/iPadOS/Android target uygulamalarını içerir.

## 7. İlk sprint için net başlangıç listesi

1. CARD-001 için Android cache lifecycle spike ve test fixture'ı.
2. CARD-002 için `ShareGateway` + iPad origin.
3. `SharePolicy` testlerini kırmızı yaz; dört bypass'ı görünür hale getir.
4. Brand/Product/Legal karar oturumunu aç ve Faz 1 çıktıları için sahip/tarih belirle.
5. Mevcut beş karttan representative fixture kataloğu çıkar: TR/EN, profit/neutral/loss, inflation partial, long value.
6. `SharePayload` projection API'sini UI değiştirmeden ekle.

Bu sıra, görsel refactor başlamadan önce ortak riskleri kapatır ve yeni kart sisteminin yanlış veri/yanlış marka varsayımı üzerine kurulmasını engeller.
