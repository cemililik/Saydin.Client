# Saydın Client — Agent Kuralları

## Proje Bağlamı

Saydın Flutter mobil uygulaması. Türk kullanıcılara yönelik finansal "ya alsaydım?" hesaplama arayüzü.

- **Flutter versiyonu:** 3.41.4 (single source of truth: [pubspec.yaml](pubspec.yaml) `environment.flutter`)
- **Flutter binary:** `flutter` (PATH'te olmalı; kurulum için bkz. [Flutter docs](https://docs.flutter.dev/get-started/install))
- **Platform:** iOS + Android
- **Mimari:** Feature-first Clean Architecture + BLoC

---

## Mimari Kurallar (KESINLIKLE UYULACAK)

### Feature Yapısı

Her feature şu üç katmana sahip OLMAK ZORUNDADIR:

```
features/<feature_name>/
├── data/
│   ├── models/          ← JSON deserializasyon modelleri
│   └── repositories/    ← Repository implementasyonları
├── domain/
│   ├── entities/        ← Saf Dart sınıfları, Flutter import YOK
│   ├── repositories/    ← Abstract repository interface'leri
│   └── usecases/        ← Use case sınıfları
└── presentation/
    ├── bloc/            ← BLoC, Event, State
    ├── pages/           ← Tam sayfa widget'lar
    └── widgets/         ← Sayfada kullanılan küçük widget'lar
```

**Katman bağımlılığı:** `presentation → domain ← data`

### Domain Katmanı Kuralları

```dart
// DOĞRU ✓ — domain entity saf Dart, para alanı Decimal (Faz 3)
import 'package:decimal/decimal.dart';
class WhatIfResult {
  final String assetSymbol;
  final Decimal finalValueTry;   // para → Decimal (double/num YASAK); JSON'dan MoneyParser.requireDecimal
  final double profitLossPercent; // yüzde/oran display-only → double serbest
  final DateTime calculatedAt;
}

// YANLIŞ ✗ — domain'de Flutter import YASAK
import 'package:flutter/material.dart';  // domain katmanında YOK
```

### BLoC Kuralları

- Her **sayfa** için bir BLoC (widget başına değil)
- BLoC içinde HTTP çağrısı YASAK — Use Case çağrılır
- BLoC içinde `dart:io` import YASAK

```dart
// DOĞRU ✓
class WhatIfBloc extends Bloc<WhatIfEvent, WhatIfState> {
  final CalculateWhatIf _calculateWhatIf;  // Use Case

  WhatIfBloc(this._calculateWhatIf) : super(WhatIfInitial()) {
    on<WhatIfCalculateRequested>(_onCalculateRequested);
  }
}

// YANLIŞ ✗
class WhatIfBloc extends Bloc<...> {
  final http.Client _httpClient;  // HTTP client BLoC'ta YASAK
}
```

### Widget Kuralları

- Widget içinde HTTP çağrısı YASAK
- `setState` ile yönetilen sayfalar BLoC kullanıyorsa YASAK
- `print()` YASAK — `debugPrint()` veya logger kullan

---

## Hata Modeli

- **Tip:** `sealed class AppError` ([lib/core/error/app_error.dart](lib/core/error/app_error.dart))
- **Varyantlar** (örnek): `NoInternetError`, `ServerError`, `PriceNotFoundError`, `DailyLimitError`, `UnknownError`
- **BLoC state**: hata mesajı **string** taşımaz — `AppError` tipi taşır
- **Widget**: hata varyantını `switch` ile `context.l10n.<key>`'e çözer
- **Sealed switch zorunlu** — `exhaustive_cases` analyzer kuralı yeni varyantın her switch'te ele alınmasını dayatır
- **Dio → AppError** dönüşümü: `lib/core/network/dio_error_mapper.dart` (interceptor sonrası)

```dart
// Widget'ta hata mesajı çözümü
final message = switch (state.error) {
  NoInternetError() => context.l10n.errorNoInternet,
  ServerError() => context.l10n.errorServer,
  PriceNotFoundError() => context.l10n.errorPriceNotFound,
  DailyLimitError() => context.l10n.errorDailyLimit,
  UnknownError() => context.l10n.errorUnknown,
};
```

---

## Dependency Injection

- **Çatı:** `get_it` (manuel kayıt, code-gen YOK)
- **Tek dosya:** [lib/core/di/injection.dart](lib/core/di/injection.dart) — tüm kayıtlar burada
- **Lifecycle:**
  - `registerLazySingleton` — repository, use case, paylaşılan servis (ApiClient, ErrorReporter, SettingsCubit gibi single-instance)
  - `registerFactory` — BLoC'lar (her sayfa girişinde fresh instance; state leakage yok)
- **Init:** `main()` içinde `configureDependencies()` çağrısı; async ise (PackageInfo gibi) `await`

```dart
// lib/core/di/injection.dart
sl.registerLazySingleton<IWhatIfRepository>(
  () => WhatIfRepositoryImpl(sl<ApiClient>()),
);
sl.registerLazySingleton(() => CalculateWhatIf(sl()));
sl.registerFactory(() => WhatIfBloc(sl()));
```

---

## Test Kuralı

- **Çerçeve:** `flutter_test` (built-in)
- **BLoC test:** `bloc_test` paketinin `blocTest`'ı — state geçişlerini sıralı assert et
- **Mocking:** `mocktail` ZORUNLU. `mockito` YASAK (code-gen istemiyoruz; ek dependency ve build-time maliyet)
- **Konum:** `test/features/<feature>/{data,domain,presentation}/...` — `lib/` ile parallel
- **Coverage hedefi:** baseline %60+; her PR'da düşürmemek hedef
- **`flutter test --coverage`** CI'da çalışır; sonuç Codecov'a yüklenir
- **Üretilmiş mock dosyaları commit'lenmez** (zaten code-gen kullanılmadığı için ortaya çıkmaz)

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalculateWhatIf extends Mock implements CalculateWhatIf {}

blocTest<WhatIfBloc, WhatIfState>(
  'success path',
  setUp: () {
    when(() => mockUseCase(any())).thenAnswer((_) async => fixtureResult);
  },
  build: () => WhatIfBloc(mockUseCase),
  act: (b) => b.add(const WhatIfCalculateRequested(...)),
  expect: () => [/* sıralı state'ler */],
);
```

---

## Kod Standartları

### Finansal Değer Gösterimi

```dart
// DOĞRU ✓ — para Decimal'da tutulur, gösterimde Türkçe locale ile formatla
import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';
final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final Decimal amount = Decimal.parse('47010.34');  // para → Decimal (double/num YASAK)
final display = formatter.format(amount.toDouble()); // "₺47.010,34" — .toDouble() SADECE gösterimde

// Yüzde — merkezi PercentageFormatter kullan (işaret + tr_TR locale)
final display = PercentageFormatter.signed(3.70);   // "+%3,70"  (lib/core/utils/percentage_formatter.dart)

// YANLIŞ ✗
"\$${amount.toStringAsFixed(2)}"  // Dolar işareti, nokta separator
final num price = 47010.34;        // para için num/double — Decimal kullan
```

### Kar/Zarar Renk Kodu

```dart
// DOĞRU ✓ — renk körü erişilebilirliği için ikon da ekle
Color profitColor = isProfit ? Colors.green.shade700 : Colors.red.shade700;
Icon profitIcon = isProfit ? Icon(Icons.trending_up) : Icon(Icons.trending_down);

// Sadece renkle göstermek YASAK (erişilebilirlik)
```

### Null Safety

```dart
// YANLIŞ ✗ — null assertion açıklama gerektiriyor
final value = result!.price;

// DOĞRU ✓
final value = result?.price ?? 0;
// veya gerekçesiyle:
// result! burada null olamaz çünkü BLoC state kontrolü yapıldı
```

---

## Commit Kuralı (KRİTİK)

### Conventional Commits (ZORUNLU)

Commit mesajları **Conventional Commits** formatında olmalıdır.

```
<tip>(<kapsam>): <açıklama>
```

| Prefix | Anlam | Örnek |
|--------|-------|-------|
| `feat:` | Yeni özellik (MINOR bump kandidi) | `feat: portföy ekranı eklendi` |
| `fix:` | Hata düzeltme (PATCH bump kandidi) | `fix: grafik render hatası düzeltildi` |
| `perf:` | Performans iyileştirme (PATCH) | `perf: liste scroll performansı iyileştirildi` |
| `revert:` | Geri alma (PATCH) | `revert: son değişiklik geri alındı` |
| `feat!:` / `fix!:` | Breaking change (MAJOR) | `feat!: API v2'ye geçildi` |
| `chore:` | Bakım | `chore: bağımlılık güncellendi` |
| `docs:` | Dokümantasyon | `docs: README güncellendi` |
| `ci:` | CI/CD | `ci: workflow düzeltildi` |
| `style:` | Format | `style: format düzeltmesi` |
| `refactor:` | Refactor | `refactor: widget yapısı sadeleştirildi` |
| `test:` | Test | `test: bloc testi eklendi` |

Kapsam isteğe bağlıdır: `feat(portfolio):`, `fix(auth):` gibi.

> Versiyon numarası **tag adından** belirlenir (aşağıdaki "Release Kuralı" bölümü). Commit prefix'i sadece sürüm planlamasına ipucu verir, otomatik bump'lamaz.

### Build Öncesi Kontrol

**Kod değişikliklerini commit etmeden önce mutlaka analiz ve testleri çalıştır.**

```bash
flutter analyze --fatal-infos
flutter test
```

Analiz veya test başarısız olursa commit atma, önce hatayı düzelt. Pre-commit hook ([.githooks/pre-commit](.githooks/pre-commit)) bu kontrolleri otomatik çalıştırır — etkinleştirme: `git config core.hooksPath .githooks`.

---

## Release Kuralı (KRİTİK)

Saydın **tag-driven** release modelini kullanır. `main`'e push tek başına store'a deployment YAPMAZ — sadece `v*` formatında annotated tag push'lamak release tetikler.

### Tag → Kanal Eşleşmesi

| Tag formatı | Kanal | Play Store | TestFlight | GitHub Environment |
|---|---|---|---|---|
| `v0.2.0-rc.1` | staging | `internal` (draft) | beta | `staging` (oto-onay) |
| `v0.2.0` | production | `production` (%10 staged) | beta | `production` (**manuel approval**) |

Production rollout `userFraction: 0.1` ile başlar — Play Console'dan elle %25 → %50 → %100 promote edilir.

### Release Akışı

1. `main` güncel ve [CI](https://github.com/cemililik/Saydin.Client/actions) yeşil olmalı.
2. **Annotated** tag oluştur (lightweight tag YASAK — release notes tag mesajından alınır):

   ```bash
   git tag -a v0.2.0 -m "v0.2.0

   ✨ Portföy ekranı eklendi.
   🐛 Grafik render hatası düzeltildi.

   =====LANG_SEPARATOR=====

   ✨ New portfolio screen.
   🐛 Fixed chart rendering bug.
   "
   ```

3. Tag'i push'la: `git push origin v0.2.0`
4. [.github/workflows/release.yml](.github/workflows/release.yml) tetiklenir:
   - **Guard** — tag main'in atası mı kontrol eder
   - **Detect channel** — `-rc.*` suffix'ine bakar, tag mesajını TR/EN'e ayırır
   - **Release Android** — signed AAB → Play Store
   - **Release iOS** — signed IPA → TestFlight
   - **GitHub Release** — AAB + IPA + tag mesajıyla
5. Production tag ise GitHub Environment `production` manuel onay bekler.

### Tag Mesajı Formatı

- **İlk satır:** Tag adı (örn. `v0.2.0`) — GitHub Release başlığı olur
- **Boş satır**
- **Türkçe release notes** — Play Store/TestFlight TR sekmesine yazılır (≤500 karakter)
- **Boş satır + `=====LANG_SEPARATOR=====` + boş satır**
- **İngilizce release notes** — Play Store/TestFlight EN-US sekmesine yazılır (≤500 karakter)

Separator yoksa TR ve EN için aynı metin kullanılır. Lightweight tag (`-a` olmadan) için son commit subject'i fallback'tir — önerilmez.

### Versiyon Numarası

Tag adı `vX.Y.Z` veya `vX.Y.Z-rc.N` olmalı. RC suffix'i otomatik strip edilir:
- `v0.2.0-rc.1` → `version_name=0.2.0`, `is_rc=true`
- `v0.2.0` → `version_name=0.2.0`, `is_rc=false`

`build_number` her tetikte `github.run_number`'dan gelir (her zaman artan).

### Yasak

- Lightweight tag (`git tag v0.2.0` — `-a` olmadan) — annotated message yok
- Tag silip yeniden push (`git push --delete` + yeni tag) — Play Console'da çift sürüm
- Tag'i `main`'de olmayan bir commit'e koyma — guard job hata verir

---

## Lokalizasyon Kuralları (KRİTİK)

Saydın **iki dilli**: Türkçe (varsayılan) + İngilizce.

**Tüm kullanıcıya görünen string'ler aşağıdaki dosyalara EŞZAMANLI eklenmelidir:**
- `lib/l10n/app_tr.arb` — Türkçe (kaynak)
- `lib/l10n/app_en.arb` — İngilizce

> Tek dilli ekleme YASAK — eksik dilde runtime fallback sessizce devreye girer, kullanıcıya İngilizce'de Türkçe key adı görünür, testlerde yakalanmaz.

```dart
// YANLIŞ ✗ — hardcoded Türkçe
Text('Hesapla')

// DOĞRU ✓
Text(context.l10n.calculate)
```

Her iki ARB dosyası paralel doldurulur:

```json
// lib/l10n/app_tr.arb
{
  "@@locale": "tr",
  "calculate": "Hesapla",
  "profitMessage": "{amount} kazanç ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": { "type": "String" },
      "percent": { "type": "String" }
    }
  }
}

// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "calculate": "Calculate",
  "profitMessage": "{amount} profit ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": { "type": "String" },
      "percent": { "type": "String" }
    }
  }
}
```

Placeholder kullanan key'lerde `@<key>` meta nesnesi HER İKİ dosyada da bulunmalı.

`flutter gen-l10n` ile üretilmiş `lib/l10n/app_localizations*.dart` dosyaları commit'lenir; `analysis_options.yaml`'da exclude'da olduğu için analyzer dokunmaz.

Senkron kontrolü:
```bash
diff <(jq -r 'keys[]' lib/l10n/app_tr.arb | grep -v '^@' | sort) \
     <(jq -r 'keys[]' lib/l10n/app_en.arb | grep -v '^@' | sort)
# boş çıktı = senkron
```

### Tarih Formatı

```dart
// DOĞRU ✓ — Türk tarihi: gün.ay.yıl
DateFormat('dd.MM.yyyy', 'tr_TR').format(date)  // "01.03.2020"

// YANLIŞ ✗
date.toString()  // "2020-03-01"
```

### Sayı Formatı

```dart
// DOĞRU ✓ — Türkçe: ondalık ayraç virgül, binler noktası
NumberFormat.decimalPattern('tr_TR').format(47010.34)  // "47.010,34"
```

---

## Sabitler

```dart
// DOĞRU ✓ — merkezi sabitler
// core/constants/app_colors.dart
class AppColors {
  static const profit = Color(0xFF2E7D32);
  static const loss = Color(0xFFC62828);
}

// core/network/api_endpoints.dart
class ApiEndpoints {
  static const whatIfCalculate = '/v1/what-if/calculate';
  static const assets = '/v1/assets';
}

// YANLIŞ ✗ — widget içinde sabit
Color myColor = Color(0xFF2E7D32);  // magic number
```

---

## Tema (Light / Dark / System)

- **Tip:** `AppThemeMode` enum (`system` / `light` / `dark`)
- **Konum:** [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) — `ThemeData` (light/dark) tanımları
- **Kullanıcı tercihi:** `SettingsCubit` → `SharedPreferences`'ta saklanır
- **MaterialApp:** `themeMode: settings.themeMode.toMaterial()` ile bağlanır
- **Widget'ta renk seçimi tema-aware OLMALI:**

```dart
// YANLIŞ ✗ — sabit renk; dark mode'da kontrast kırılır
Container(color: Colors.grey.shade100)

// DOĞRU ✓ — semantic color
Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)

// Domain-specific (kar/zarar gibi) için AppColors:
Container(color: AppColors.profit)  // tema-bağımsız sabitler
```

---

## API İstemcisi

- **Base URL:** `--dart-define=API_BASE_URL=<url>` ile geçilir — hardcode YASAK
  ```bash
  flutter run --dart-define=API_BASE_URL=https://api-staging.saydin.app
  ```
- **Aktif backend URL** dev cihazda değişken (ngrok tüneli) — güncel URL için takım ile eşgüdüm; URL'i burada listelemekten kaçınılır (commit history'sinde URL leak riski)
- **Interceptor zinciri** ([lib/core/network/](lib/core/network/)):
  1. `DeviceIdInterceptor` — `X-Device-ID` header (UUID v4, `FlutterSecureStorage`'dan)
  2. `DeviceInfoInterceptor` — `X-Device-Info` header (app version, build number, platform)
  3. `LanguageInterceptor` — `Accept-Language` header (kullanıcı seçimi)
  4. `RetryInterceptor` — GET/HEAD için 2x exponential backoff
- **Hata mapping:** `DioErrorMapper` → `AppError` (sealed class)
- **Timeout:** 15s connect, 15s receive

---

## Observability ve KVKK

### Sentry

- **Etkinleştirme:** `--dart-define=SENTRY_DSN=<dsn>` (tanımlı değilse Sentry sessizce devre dışı kalır)
- **PII scrubber ZORUNLU:** [lib/core/observability/sentry_pii_scrubber.dart](lib/core/observability/sentry_pii_scrubber.dart) — breadcrumb ve event'lerden kullanıcıya ait bilgileri temizler
- **Log YASAK:** TC kimlik, telefon, e-posta, isim, IP, device ID — log'a yazılmaz, breadcrumb'a girmez

### KVKK Madde 11/12 Uyumu

- **Madde 11 (bilgi talebi):** Backend `/v1/account/data-export` üzerinden tetiklenir
- **Madde 12 (silme):** [lib/features/account/](lib/features/account/) — backend 200 OK olmadan **local cleanup başlamaz** (race condition önle)
- **Cross-feature reset:** Hesap silindiğinde favorites, scenarios, portfolio cache'leri **tek transaction'da** temizlenir
- **Device ID:** Sadece `FlutterSecureStorage` (`SharedPreferences`'a YASAK — şifrelenmez)

---

## Cihaza Deploy (KRİTİK)

**Test cihazı:** iPhone "C.I." — `00008101-00013C6A02B9003A` (iOS 18.6)

```bash
# Debug modda iPhone'a deploy (varsayılan)
flutter run \
  --dart-define=API_BASE_URL=<aktif-staging-URL> \
  --device-id 00008101-00013C6A02B9003A

# Release modda iPhone'a deploy
flutter run \
  --dart-define=API_BASE_URL=<aktif-staging-URL> \
  --device-id 00008101-00013C6A02B9003A \
  --release
```

> `<aktif-staging-URL>` placeholder'ı dev tüneline (ngrok / cloudflared) işaret eder. Tünel URL'i sık sık değişir — committed dosyada hardcode edilmez; güncel URL takım iletişim kanalından alınır.

- Kullanıcı "iPhone'a gönder" veya "cihaza deploy et" dediğinde **debug mod** varsayılandır (aksi belirtilmezse)
- Cihaz bağlı değilse önce `flutter devices` ile kontrol et

---

## Yasak Listesi (Özet)

Tüm yasaklar tek bakışta. Her kategori için detay yukarıdaki ilgili bölümde.

### Mimari
- Widget içinde HTTP çağrısı
- BLoC'ta HTTP client (`Dio`, `ApiClient`, `http.Client` field)
- BLoC içinde `dart:io` import
- Domain katmanında Flutter import (`package:flutter/...`)
- `setState` BLoC kullanan sayfada

### Kod Stili
- `print()` (kullan: `debugPrint()`)
- Hardcoded Türkçe string (kullan: `context.l10n.<key>`)
- Hardcoded renk widget içinde (kullan: `Theme.of(context)` veya `AppColors.*`)
- Hardcoded API URL (kullan: `--dart-define=API_BASE_URL`)
- `double` / `float` / `num` para tutarı için (kullan: `Decimal` — JSON'dan `MoneyParser.requireDecimal`; gösterimde `.toDouble()`)
- BLoC state'inde hata mesajı string (kullan: `AppError` tipi)
- `Equatable.props` içinde function field (callback'ler parent widget'tan parametre olur)

### L10n
- Tek dilli key ekleme (TR olmadan EN veya tersi)
- `@<key>` placeholder meta nesnesini tek dilde tanımlama

### Test
- `mockito` kullanma (kullan: `mocktail` — code-gen istemiyoruz)
- Code-generated mock dosyaları commit (zaten gitignore'da)

### Release
- Lightweight tag (annotated kullan: `git tag -a vX.Y.Z -m "..."`)
- `main`'de olmayan commit'e tag (guard job hata verir)
- Tag silip yeniden push (Play Console çift sürüm — semver bump et)
- `=====LANG_SEPARATOR=====` ayracını unutma

### Güvenlik / KVKK
- PII (kimlik, telefon, e-posta, isim, IP, device ID) log'a / breadcrumb'a yazma
- Device ID `SharedPreferences`'ta (kullan: `FlutterSecureStorage`)
- Hesap silme: backend 200 OK olmadan local cleanup

### Dokümantasyon
- ASCII art diyagram (Mermaid kullan)
- Flutter'a özgü doc'u kök `docs/`'a koyma (kullan: `<repo-kökü>/docs/`)

---

## Dokümantasyon Standardı

### Nereye Yazılır?

| Kapsam | Konum |
|--------|-------|
| Flutter'a özgü mimari, BLoC, hata yönetimi, DI, ağ katmanı | `docs/architecture.md` |
| Flutter geliştirme iş akışı (komutlar, env, build, sorun giderme) | `docs/development-guide.md` |
| Proje geneli mimari (istemci + servisler arası ilişki, API sözleşmesi) | Kök `docs/` dizini |
| Mimari kararlar (ADR) | Kök `docs/decisions/` dizini |

### Kurallar

- **Diyagram ve akış şemaları Mermaid ile çizilir** — ASCII art YASAK. Markdown dosyalarında ` ```mermaid ` blokları kullan.
- **Flutter'a özgü** her doküman `docs/` içine gider — Saydın meta repo'sundaki kök `docs/` içine konmaz.
- Kök `docs/`'a yalnızca birden fazla bileşeni (istemci + servisler) kapsayan belgeler eklenir.
- Yeni özellik eklendiğinde `docs/architecture.md` güncellenir (yeni katman, pattern, paket).
- `development-guide.md` iş akışı değiştiğinde güncellenir (yeni komut, env değişkeni, sorun).
- Büyük mimari karar alındığında kök `docs/decisions/ADR-XXX-<konu>.md` oluşturulur.
- Dokümanlar kod değişikliğiyle aynı commit'te güncellenir; ayrı PR açılmaz.
