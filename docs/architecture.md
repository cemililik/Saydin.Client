# Saydin.Client — Mimari

## Genel Yapı

Feature-first Clean Architecture + BLoC pattern. Her özellik kendi klasöründe bağımsız olarak bulunur.

```
lib/
├── core/                          ← Özelliklerden bağımsız altyapı
│   ├── constants/                 ← AppColors, ApiEndpoints
│   ├── di/                        ← injection.dart (get_it servis locator)
│   ├── error/                     ← AppError, DioErrorMapper, ErrorReporter
│   ├── l10n/                      ← L10nContext extension (context.l10n)
│   ├── network/                   ← ApiClient, DeviceIdInterceptor, LanguageInterceptor, RetryInterceptor
│   ├── theme/                     ← AppTheme (light/dark ThemeData), ThemeModeMapper
│   └── widgets/                   ← InflationToggle, SharePreviewSheet, SettingsIconButton
├── features/
│   ├── what_if/                   ← Ana özellik: "ya alsaydım" hesaplama
│   │   ├── data/
│   │   │   ├── models/            ← AssetModel, WhatIfResultModel, ReverseWhatIfResponseModel (fromJson)
│   │   │   └── repositories/     ← WhatIfRepositoryImpl (Dio çağrıları burada)
│   │   ├── domain/
│   │   │   ├── entities/          ← Asset (allowedAmountTypes getter dahil), WhatIfResult, ReverseWhatIfResult
│   │   │   ├── repositories/     ← WhatIfRepository (abstract interface)
│   │   │   └── usecases/         ← GetAssets, CalculateWhatIf, CalculateReverseWhatIf
│   │   └── presentation/
│   │       ├── bloc/              ← WhatIfBloc, WhatIfEvent, WhatIfState, WhatIfFormInput
│   │       ├── pages/             ← WhatIfPage
│   │       └── widgets/           ← AssetSelector (bottom sheet + arama), DateInput (asset tarih aralığı),
│   │                                 AmountInput (dinamik tip/ikon), ResultCard, ReverseResultCard,
│   │                                 ResultChart (fl_chart), ReverseShareCardWidget
│   ├── scenarios/                 ← Kaydedilen senaryolar
│   │   ├── data/
│   │   │   ├── models/            ← SavedScenarioModel (fromJson)
│   │   │   └── repositories/     ← ScenariosRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/          ← SavedScenario
│   │   │   ├── repositories/     ← ScenariosRepository (abstract interface)
│   │   │   └── usecases/         ← GetScenarios, SaveScenario, DeleteScenario
│   │   └── presentation/
│   │       ├── bloc/              ← ScenariosBloc, ScenariosEvent, ScenariosState
│   │       ├── pages/             ← ScenariosPage (swipe-to-delete, refresh)
│   │       └── widgets/           ← ScenarioCard (avatar, Dismissible)
│   └── settings/                  ← Kullanıcı ayarları (tema, gelecek tercihler)
│       ├── data/
│       │   └── repositories/     ← SettingsRepositoryImpl (SharedPreferences)
│       ├── domain/
│       │   ├── entities/          ← AppSettings (themeMode, language + copyWith)
│       │   └── repositories/     ← SettingsRepository (abstract interface)
│       └── presentation/
│           ├── cubit/             ← SettingsCubit (LazySingleton)
│           ├── pages/             ← SettingsPage
│           └── widgets/           ← ThemeSelectorTile, LanguageSelectorTile (SegmentedButton)
└── l10n/                          ← flutter gen-l10n çıktısı (commit'lenir)
    ├── app_localizations.dart
    ├── app_localizations_tr.dart
    ├── app_localizations_en.dart
    ├── app_tr.arb                 ← Türkçe kaynak dosya
    └── app_en.arb                 ← İngilizce kaynak dosya
```

## Katman Mimarisi

```
presentation → domain ← data
```

- `data` katmanı `domain` repository interface'lerini implement eder
- `presentation` katmanı `domain` entity ve use case'lerini kullanır
- `data` ve `presentation` birbirini referans almaz
- **Domain katmanında `package:flutter` import YASAKTIR** — saf Dart kalmalıdır

## Bağımlılık Enjeksiyonu (get_it)

`lib/core/di/injection.dart` içinde `sl` (service locator) nesnesi merkezi olarak konfigüre edilir. Code generation (`injectable`, `build_runner`) **kullanılmaz** — kayıtlar elle yazılır.

| Kayıt Tipi | Kullanıldığı Yer | Gerekçe |
|---|---|---|
| `registerLazySingleton` | ApiClient, Repository, UseCase, DioErrorMapper, ErrorReporter, SettingsCubit | Bir kez oluşturulur, tüm uygulama boyunca paylaşılır |
| `registerFactory` | WhatIfBloc, ComparisonBloc, PortfolioBloc, DcaBloc, ScenariosBloc | Her sayfa açılışında yeni instance — eski state sızmaz |

```dart
// Sayfa açılırken BLoC sağlanır
BlocProvider(
  create: (_) => sl<WhatIfBloc>()..add(const WhatIfAssetsRequested()),
  child: const WhatIfPage(),
)
```

## BLoC State Makineleri

### WhatIfBloc

Form alanları `WhatIfFormInput` veri sınıfında taşınır ve tüm state'lere gömülüdür. Bu sayede hesaplama başarısız olsa bile form değerleri kaybolmaz.

**Hesaplama Modu:** `CalculationMode` enum'u (`normal` | `reverse`) ile iki hesaplama modu desteklenir. `SegmentedButton` ile kullanıcı mod değiştirebilir.

```
WhatIfInitial
    │
    │ WhatIfAssetsRequested
    ▼
WhatIfAssetsLoading
    ├─ başarı ──► WhatIfAssetsLoaded(assets, formInput)
    └─ hata ───► WhatIfFailure(assets: [], error, formInput)

WhatIfAssetsLoaded / WhatIfSuccess / WhatIfFailure
    │
    │ WhatIfSymbolChanged
    ▼
    Aynı state, formInput güncellenerek yeniden emit edilir.
    • amountType yeni asset için geçersizse → 'try'e sıfırlanır
    • buyDate/sellDate asset'in [firstDate, lastDate] dışındaysa → sıkıştırılır,
      formInput.dateAdjusted = true (tek seferlik flag — UI snackbar gösterir, sonra false olur)

    │ WhatIfModeChanged(CalculationMode)
    ▼
    formInput.calculationMode güncellenir.
    Ters modda amountType otomatik 'try'e zorlanır (hedef tutar yalnızca TL).

    │ WhatIfBuyDateChanged / WhatIfSellDateChanged / WhatIfAmountTypeChanged
    ▼
    Aynı state, formInput güncellenerek yeniden emit edilir

    │ WhatIfCalculateRequested (normal mod)
    ▼
WhatIfCalculating(assets, formInput)
    ├─ başarı ──► WhatIfSuccess(assets, result: WhatIfResult, formInput)
    └─ hata ───► WhatIfFailure(assets, error, formInput)

    │ WhatIfReverseCalculateRequested (ters mod)
    ▼
WhatIfCalculating(assets, formInput)
    ├─ başarı ──► WhatIfSuccess(assets, reverseResult: ReverseWhatIfResult, formInput)
    └─ hata ───► WhatIfFailure(assets, error, formInput)
```

**`WhatIfSuccess` state'i:** `result` (nullable `WhatIfResult`) ve `reverseResult` (nullable `ReverseWhatIfResult`) taşır. Mod'a göre yalnızca biri dolu olur.

**`WhatIfFormInput` alanları:**

| Alan | Tip | Açıklama |
|---|---|---|
| `selectedSymbol` | `String?` | Seçili asset sembolü |
| `buyDate` | `DateTime?` | Alış tarihi |
| `sellDate` | `DateTime?` | Satış tarihi (opsiyonel) |
| `amountType` | `String` | `try` \| `units` \| `grams` |
| `amount` | `num?` | Tutar (replay/senaryo yüklemede doldurulur) |
| `calculationMode` | `CalculationMode` | `normal` veya `reverse` — hesaplama modunu belirler |
| `includeInflation` | `bool` | Enflasyon düzeltmesi dahil mi |
| `dateAdjusted` | `bool` | Sembol değişince tarih sıkıştırıldıysa `true` — bir kez UI'a iletildikten sonra `copyWith` ile otomatik `false`'a döner (one-shot flag) |

**State kuralları:**
- Tüm state'ler `Equatable` implement eder → gereksiz widget rebuild önlenir
- `List<Asset>` alanları `List.unmodifiable()` ile sarılır — dış mutasyon engellenir
- **Hata mesajı BLoC üretmez** — yalnızca `AppError` tipi taşır (bkz. ADR-006)

### ScenariosBloc

Silme işlemi **optimistic** yapılır: API çağrısından önce öğe UI'dan kaldırılır, hata durumunda liste eski haline döndürülür.

```
ScenariosInitial
    │ ScenariosRequested
    ▼
ScenariosLoading
    ├─ başarı ──► ScenariosLoaded(scenarios)
    └─ hata ───► ScenariosFailure(scenarios: [], error)

ScenariosLoaded
    │ ScenarioDeleteRequested
    ▼
    ScenariosLoaded(scenarios - silinen)   ← hemen (optimistic)
    └─ API hata ──► ScenariosFailure(scenarios orijinal, error)

    │ ScenarioSaveRequested
    ├─ duplicate ──► ScenariosDuplicate(scenarios)  ← API'ye gidilmez, UI snackbar gösterir
    ▼
ScenariosSaving(scenarios)
    ├─ başarı ──► ScenariosLoaded([yeni, ...scenarios])
    └─ hata ───► ScenariosFailure(scenarios, error)
```

**Duplicate kontrolü:** Kaydetmeden önce mevcut liste; `assetSymbol` + `buyDate` + `sellDate` + `amount` + `amountType` bileşimine göre taranır. Aynı kombinasyon zaten varsa `ScenariosDuplicate` emit edilir — API çağrısı yapılmaz.

## Domain Mantığı — Asset

`Asset` entity'si saf Dart olmasına karşın tutar tipi kısıtlarını ve veri aralığını da taşır:

```dart
class Asset {
  final String symbol;
  final String displayName;
  final String category;
  final DateTime? firstDate;   // Veritabanındaki en eski fiyat tarihi
  final DateTime? lastDate;    // Veritabanındaki en yeni fiyat tarihi

  // Tutar tipi kısıtı:
  // 'precious_metal' → ['try', 'grams']
  // diğerleri        → ['try', 'units']
  List<String> get allowedAmountTypes { ... }
}
```

`firstDate`/`lastDate` alanları `GET /assets` yanıtından (`firstPriceDate`/`lastPriceDate`) parse edilir ve `DateInput` widget'larına geçirilerek takvim aralığı kısıtlanır.

Asset değiştiğinde `WhatIfBloc._onSymbolChanged`:
1. Mevcut `amountType` yeni asset için geçersizse → `'try'`'a sıfırlar
2. `buyDate`/`sellDate` yeni asset'in `[firstDate, lastDate]` dışındaysa → sıkıştırır (`dateAdjusted = true`)

`AmountInput` widget'ı da `allowedAmountTypes` listesini kullanarak dropdown seçeneklerini ve prefix ikonu dinamik olarak gösterir:

| amountType | Prefix ikon |
|---|---|
| `try` | `Icons.currency_lira` |
| `units` | `Icons.tag` |
| `grams` | `Icons.scale_outlined` |

## Ağ Katmanı

### Interceptor Zinciri

```
İstek gönderilecek
    │
    ▼
DeviceIdInterceptor   ← Her isteğe X-Device-ID header ekler
    │
    ▼
LanguageInterceptor   ← Her isteğe Accept-Language header ekler
    │
    ▼
RetryInterceptor      ← GET/HEAD: max 2 yenileme, üstel backoff
    │
    ▼
Sunucu
```

### DeviceIdInterceptor

`FlutterSecureStorage` ile `saydin_device_id` anahtarı altında UUID v4 saklanır.
**Fallback:** Storage erişimi başarısız olursa oturum süreli ephemeral UUID kullanılır — kullanıcı hata görmez.

### LanguageInterceptor

Her istekte `Accept-Language` header'ını `AppLocaleHolder.code` değerinden okuyarak ekler. `AppLocaleHolder` basit bir statik holder'dır — `SettingsCubit` dil değiştiğinde `update()` çağırarak günceller.

| Kullanıcı seçimi | Accept-Language | Sonuç |
|---|---|---|
| Türkçe | `tr` | Backend Türkçe yanıt verir |
| English | `en` | Backend İngilizce yanıt verir |
| Sistem | Platform locale | Cihaz diline göre |

### RetryInterceptor

- Kapsam: yalnızca GET ve HEAD (idempotent)
- Tetikleyici: `connectionError`, `receiveTimeout`, `connectionTimeout`
- Yenilenmeyenler: 4xx, 5xx — bunlar domain hatasına dönüştürülür
- Gecikme: `min(200 * 2^attempt, 2000) + jitter(0..100)` ms

## Hata Yönetimi

### AppError Hiyerarşisi (`sealed class`)

```dart
sealed class AppError { ... }
class PriceNotFoundError extends AppError { ... }   // 404
class DailyLimitError   extends AppError {           // 429
  final DateTime resetAt;
}
class NoInternetError   extends AppError { ... }    // connectionError
class ServerError       extends AppError {           // 5xx
  final int? statusCode;
}
class UnknownError      extends AppError { ... }    // catch-all
```

`sealed` keyword'ü exhaustive `switch` sağlar: yeni hata tipi eklenip widget güncellenmezse **derleme hatası** alınır.

### Akış

```
DioException
    │
    ▼
DioErrorMapper.map()   ← HTTP kodu → AppError dönüşümü
    │
    ▼
WhatIfBloc             ← AppError'ı state'e koyar, mesaj üretmez
    │
    ├─ ServerError / UnknownError ──► ErrorReporter.report() → Sentry
    │
    └─ diğerleri ───────────────────► Sentry'ye gönderilmez (beklenen akış)
    │
    ▼
Widget (BlocConsumer listener)
    └─ switch(state.error) ──► context.l10n.errorXxx
```

### ErrorReporter (Sentry)

DSN `--dart-define=SENTRY_DSN=<dsn>` ile enjekte edilir. DSN boşsa Sentry sessizce devre dışı kalır.

```dart
// Yalnızca beklenmedik hatalar raporlanır
if (error is UnknownError || error is ServerError) {
  await _reporter.report(e, st, context: 'calculate_what_if');
}
```

## Lokalizasyon (L10n)

**Desteklenen diller:** Türkçe (`tr`, varsayılan), İngilizce (`en`)

Kaynak dosyalar: `lib/l10n/app_tr.arb` (Türkçe), `lib/l10n/app_en.arb` (İngilizce). Tüm kullanıcıya görünen string'ler buralardadır.

```bash
# Kod üretimi (ARB dosyaları değiştiğinde)
flutter gen-l10n
```

```dart
// Widget içinde kullanım
final l10n = context.l10n;   // lib/core/l10n/l10n_extensions.dart extension'ı
Text(l10n.calculate)
Text(l10n.errorPriceNotFound)
```

**Kural:** BLoC UI string üretmez. Hata metni widget katmanında `switch (state.error)` ile l10n'dan çözülür.

### Dil Seçimi

`AppSettings.language` enum'u üç seçenek sunar:

| Seçenek | `MaterialApp.locale` | `Accept-Language` |
|---|---|---|
| `AppLanguage.tr` | `Locale('tr', 'TR')` | `tr` |
| `AppLanguage.en` | `Locale('en', 'US')` | `en` |
| `AppLanguage.system` | `null` (Flutter otomatik) | Platform locale |

Dil değiştiğinde:
1. `SettingsCubit.setLanguage()` → `AppSettings` emit eder
2. `BlocBuilder<SettingsCubit>` → `MaterialApp.locale` güncellenir → UI yeniden çizilir
3. `AppLocaleHolder.update()` → Sonraki API isteklerinde `Accept-Language` güncellenir

### İstemci-Sunucu Dil Uyumu

İstemci ve sunucu aynı dili konuşur:
- **İstemci:** ARB dosyalarından `context.l10n` ile çözülen UI string'leri
- **Sunucu:** `Accept-Language` header'ına göre `.resx` dosyalarından çözülen hata mesajları ve asset isimleri

## Grafik (ResultChart)

`ResultCard` içinde `ResultChart` widget'ı (`fl_chart ^0.70.2`) ile alış-satış aralığındaki fiyat geçmişi çizilir.

### Veri Akışı

`WhatIfResult.priceHistory: List<ChartPoint>` — API'nin `priceHistory` alanından parse edilir (max 60 nokta).

### Etkileşim Modları

| Mod | Tetikleyici | Davranış |
|---|---|---|
| Tooltip | Tek dokunuş | O noktadaki tarih ve fiyatı gösterir (2 ondalık) |
| Range seçimi | Uzun basış + sürükleme | İki nokta arası dolgu + dikey çizgiler; alt çubukta tarih aralığı ve % değişim |

Range modunda tooltip devre dışı kalır (`handleBuiltInTouches: !_isRangeMode`). Dışarı tıklamak range'i temizler.

---

## Sonuç Gösterimi Kuralları

```dart
// Para birimi — Türkçe locale
NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(47010.34)  // ₺47.010,34

// Yüzde
NumberFormat.decimalPercentPattern(locale: 'tr_TR', decimalDigits: 2).format(3.70) // %370,00

// Tarih
DateFormat('dd.MM.yyyy', 'tr_TR').format(date)  // 01.03.2020

// Kar/zarar rengi + ikonu (erişilebilirlik: renkle birlikte ikon da gerekli)
Color: Colors.green.shade700 / Colors.red.shade700
Icon:  Icons.trending_up / Icons.trending_down
```

## Tema Sistemi

> ADR: [ADR-012](../../../docs/decisions/ADR-012-client-settings-architecture.md)

### ThemeData Yapısı

`core/theme/app_theme.dart` içinde `AppTheme.light` ve `AppTheme.dark` olmak üzere iki statik `ThemeData` tanımlıdır. Her ikisi de aynı seed rengi (`AppColors.primary`) ile `ColorScheme.fromSeed` kullanır.

```dart
// MaterialApp entegrasyonu (app.dart)
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: toFlutterThemeMode(settings.themeMode),  // SettingsCubit'ten
)
```

`SettingsCubit` `MaterialApp`'in **üstünde** `BlocProvider` ile sağlanır. Tema değiştiğinde `BlocBuilder` tüm MaterialApp'i rebuild eder — bu Flutter'ın önerdiği tema değiştirme yöntemidir.

### AppColors ve Dark Mode

`AppColors` profit/loss renkleri için iki set sunar:

| Renk | Light | Dark |
|------|-------|------|
| Kar (profit) | `#2E7D32` (koyu yeşil) | `#66BB6A` (açık yeşil) |
| Zarar (loss) | `#C62828` (koyu kırmızı) | `#EF5350` (açık kırmızı) |

Helper methodlar:
```dart
AppColors.profitColor(Theme.of(context).brightness)
AppColors.lossColor(Theme.of(context).brightness)
```

### BottomNavigationBar

Tema renkleri `BottomNavigationBarThemeData` üzerinden `AppTheme.light` ve `AppTheme.dark` içinde tanımlanır. Hardcoded `Colors.white` / `Color(0xFF757575)` **kullanılmaz** — `colorScheme.primary` ve `colorScheme.onSurfaceVariant` kullanılır.

---

## Ayarlar Altyapısı (Settings)

### Depolama

`SharedPreferences` (cihaz lokali). Platform bazında:
- iOS: `NSUserDefaults`
- Android: XML shared_prefs

Sunucu senkronizasyonu **yok** — tema gibi tercihler cihaza özeldir.

### SettingsCubit

```
SettingsCubit (LazySingleton)
    │
    │ load()  ← uygulama başlangıcında çağrılır
    ▼
AppSettings(themeMode: system, language: system)  ← SharedPreferences'tan okunur
    │                                                 + AppLocaleHolder.update()
    │ setThemeMode(dark)
    ▼
AppSettings(themeMode: dark, language: system)     ← emit + SharedPreferences'a yaz
    │
    │ setLanguage(en)
    ▼
AppSettings(themeMode: dark, language: en)         ← emit + SharedPreferences'a yaz
                                                      + AppLocaleHolder.update('en')
```

**Neden Cubit, BLoC değil?** Ayar değiştirme basit bir setter — event/handler deseni gereksiz.

**Neden LazySingleton, Factory değil?** Tema ve dil `MaterialApp` seviyesinde tüketilir, uygulama boyunca tek instance yeterli.

### Genişletme

Yeni ayar eklemek:
1. `AppSettings` entity'sine field ekle (`copyWith`'i güncelle)
2. `SettingsRepositoryImpl`'e okuma/yazma ekle (yeni SharedPreferences key)
3. `SettingsCubit`'e setter ekle
4. `SettingsPage`'e yeni widget ekle
5. `app_tr.arb` ve `app_en.arb`'a l10n string'leri ekle

### Navigasyon

Settings sayfasına erişim: `SettingsIconButton` (gear icon) → tüm ana sayfa AppBar'larının `actions`'ında bulunur. `Navigator.push` ile `SettingsPage`'e gider.

`SettingsCubit` `MaterialApp` üstünde olduğu için push edilen route'tan erişilemez — `SettingsIconButton` `BlocProvider.value` ile `sl<SettingsCubit>()` singleton'ını route'a geçirir.

---

## CI/CD (GitHub Actions)

`.github/workflows/ci.yml` — PR ve `main` push'ta tetiklenir.

| Job | Runner | Adımlar |
|---|---|---|
| `analyze-and-test` | ubuntu-latest | flutter pub get → gen-l10n → dart format → flutter analyze --fatal-infos → flutter test --coverage → Codecov |
| `build-android` | ubuntu-latest | APK debug (yalnızca PR) |
| `build-ios` | macos-15 | no-codesign build (yalnızca PR) |

Aynı branch için paralel çalışan iş akışı otomatik iptal edilir (`cancel-in-progress: true`).
