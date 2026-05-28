# Saydın Client — Agent Kuralları

## Proje Bağlamı

Saydın Flutter mobil uygulaması. Türk kullanıcılara yönelik finansal "ya alsaydım?" hesaplama arayüzü.

- **Flutter versiyonu:** 3.41.0
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
// DOĞRU ✓ — domain entity saf Dart
class WhatIfResult {
  final String assetSymbol;
  final Decimal finalValueTry;
  ...
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

## Kod Standartları

### Finansal Değer Gösterimi

```dart
// DOĞRU ✓ — Türkçe locale ile formatla
import 'package:intl/intl.dart';
final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final display = formatter.format(47010.34);  // "₺47.010,34"

// Yüzde
final pctFormatter = NumberFormat.decimalPercentPattern(locale: 'tr_TR', decimalDigits: 2);

// YANLIŞ ✗
"\$${amount.toStringAsFixed(2)}"  // Dolar işareti, nokta separator
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

> Versiyon numarası **tag adından** belirlenir (bkz. [Release Kuralı](#release-kuralı-kri̇ti̇k)). Commit prefix'i sadece sürüm planlamasına ipucu verir, otomatik bump'lamaz.

### Build Öncesi Kontrol

**Kod değişikliklerini commit etmeden önce mutlaka analiz ve testleri çalıştır.**

```bash
/Users/dev/development/flutter/bin/flutter analyze --fatal-infos
/Users/dev/development/flutter/bin/flutter test
```

Analiz veya test başarısız olursa commit atma, önce hatayı düzelt.

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

**Tüm kullanıcıya görünen string'ler `l10n/app_tr.arb` dosyasında olmalıdır.**

```dart
// YANLIŞ ✗ — hardcoded Türkçe
Text('Hesapla')
Text('Sonuç yükleniyor...')

// DOĞRU ✓
Text(context.l10n.calculate)
Text(context.l10n.loadingResult)
```

`app_tr.arb` formatı:
```json
{
  "@@locale": "tr",
  "calculate": "Hesapla",
  "loadingResult": "Sonuç yükleniyor...",
  "profitMessage": "{amount} kazanç ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": { "type": "String" },
      "percent": { "type": "String" }
    }
  }
}
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

## API İstemcisi

- Base URL dart-define ile geçilir — hardcode YASAK
- Aktif backend URL: `https://fumed-cleverishly-moses.ngrok-free.dev/`
- `X-Device-ID` header her istekte otomatik eklenir (interceptor)
- `FlutterSecureStorage` ile UUID oluşturulur ve saklanır

---

## Cihaza Deploy (KRİTİK)

**Test cihazı:** iPhone "C.I." — `00008101-00013C6A02B9003A` (iOS 18.6)

```bash
# Debug modda iPhone'a deploy (varsayılan)
flutter run \
  --dart-define=API_BASE_URL=https://fumed-cleverishly-moses.ngrok-free.dev/ \
  --device-id 00008101-00013C6A02B9003A

# Release modda iPhone'a deploy
flutter run \
  --dart-define=API_BASE_URL=https://fumed-cleverishly-moses.ngrok-free.dev/ \
  --device-id 00008101-00013C6A02B9003A \
  --release
```

- Kullanıcı "iPhone'a gönder" veya "cihaza deploy et" dediğinde **debug mod** varsayılandır (aksi belirtilmezse)
- Cihaz bağlı değilse önce `flutter devices` ile kontrol et

---

## Yasak Listesi

- Widget içinde HTTP çağrısı — YASAK
- `print()` — YASAK (kullan: `debugPrint()`)
- Hardcoded Türkçe string — YASAK
- Hardcoded renkler widget içinde — YASAK
- Hardcoded API URL — YASAK
- `setState` BLoC kullanan sayfada — YASAK
- `double`/`float` para tutarı için — YASAK (Dart'ta `num` veya server'dan gelen string → parse et)
- Domain katmanında Flutter import — YASAK
- BLoC'ta HTTP client — YASAK

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
