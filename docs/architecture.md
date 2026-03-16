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
│   └── network/                   ← ApiClient, DeviceIdInterceptor, RetryInterceptor
├── features/
│   └── what_if/                   ← Ana özellik: "ya alsaydım" hesaplama
│       ├── data/
│       │   ├── models/            ← JSON ↔ Dart dönüşümü (fromJson/toJson)
│       │   └── repositories/     ← WhatIfRepositoryImpl (Dio çağrıları burada)
│       ├── domain/
│       │   ├── entities/          ← Saf Dart: Asset, WhatIfResult (Flutter import yok)
│       │   ├── repositories/     ← WhatIfRepository (abstract interface)
│       │   └── usecases/         ← GetAssets, CalculateWhatIf
│       └── presentation/
│           ├── bloc/              ← WhatIfBloc, WhatIfEvent, WhatIfState
│           ├── pages/             ← WhatIfPage (tam sayfa widget)
│           └── widgets/           ← AssetSelector, DateInput, AmountInput, ResultCard
└── l10n/                          ← flutter gen-l10n çıktısı (commit'lenir)
    ├── app_localizations.dart
    ├── app_localizations_tr.dart
    └── app_tr.arb                 ← Kaynak dosya (elle düzenlenen tek dosya)
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
| `registerLazySingleton` | ApiClient, Repository, UseCase, DioErrorMapper, ErrorReporter | Bir kez oluşturulur, tüm uygulama boyunca paylaşılır |
| `registerFactory` | WhatIfBloc | Her sayfa açılışında yeni instance — eski state sızmaz |

```dart
// Sayfa açılırken BLoC sağlanır
BlocProvider(
  create: (_) => sl<WhatIfBloc>()..add(const WhatIfAssetsRequested()),
  child: const WhatIfPage(),
)
```

## BLoC State Makinesi

```
WhatIfInitial
    │
    │ WhatIfAssetsRequested
    ▼
WhatIfAssetsLoading
    ├─ başarı ──► WhatIfAssetsLoaded(assets)
    └─ hata ───► WhatIfFailure(assets: [], error: AppError)

WhatIfAssetsLoaded / WhatIfSuccess / WhatIfFailure
    │
    │ WhatIfCalculateRequested
    ▼
WhatIfCalculating(assets)
    ├─ başarı ──► WhatIfSuccess(assets, result)
    └─ hata ───► WhatIfFailure(assets, error: AppError)
```

**State kuralları:**
- Tüm state'ler `Equatable` implement eder → gereksiz widget rebuild önlenir
- `List<Asset>` alanları `List.unmodifiable()` ile sarılır — dış mutasyon engellenir
- **`WhatIfFailure` hata mesajı taşımaz** — yalnızca `AppError` tipi taşır (bkz. ADR-006)

## Ağ Katmanı

### Interceptor Zinciri

```
İstek gönderilecek
    │
    ▼
DeviceIdInterceptor   ← Her isteğe X-Device-ID header ekler
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

Kaynak dosya: `lib/l10n/app_tr.arb` — **tüm kullanıcıya görünen string'ler buradadır**.

```bash
# Kod üretimi (ARB değiştiğinde)
flutter gen-l10n
```

```dart
// Widget içinde kullanım
final l10n = context.l10n;   // lib/core/l10n/l10n_extensions.dart extension'ı
Text(l10n.calculate)
Text(l10n.errorPriceNotFound)
```

**Kural:** BLoC Türkçe string üretmez. Hata metni widget katmanında `switch (state.error)` ile l10n'dan çözülür.

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

## CI/CD (GitHub Actions)

`.github/workflows/ci.yml` — PR ve `main` push'ta tetiklenir.

| Job | Runner | Adımlar |
|---|---|---|
| `analyze-and-test` | ubuntu-latest | flutter pub get → gen-l10n → dart format → flutter analyze --fatal-infos → flutter test --coverage → Codecov |
| `build-android` | ubuntu-latest | APK debug (yalnızca PR) |
| `build-ios` | macos-15 | no-codesign build (yalnızca PR) |

Aynı branch için paralel çalışan iş akışı otomatik iptal edilir (`cancel-in-progress: true`).
