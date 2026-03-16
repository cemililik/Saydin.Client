# Saydın Client — Agent Kuralları

## Proje Bağlamı

Saydın Flutter mobil uygulaması. Türk kullanıcılara yönelik finansal "ya alsaydım?" hesaplama arayüzü.

- **Flutter versiyonu:** 3.41.0
- **Flutter binary:** `/Users/dev/development/flutter/bin/flutter`
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

- Base URL environment config'den gelir — hardcode YASAK
- `X-Device-ID` header her istekte otomatik eklenir (interceptor)
- `FlutterSecureStorage` ile UUID oluşturulur ve saklanır

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

- **Flutter'a özgü** her doküman `src/Saydin.Client/docs/` içine gider — kök `docs/` içine konmaz.
- Kök `docs/`'a yalnızca birden fazla bileşeni (istemci + servisler) kapsayan belgeler eklenir.
- Yeni özellik eklendiğinde `docs/architecture.md` güncellenir (yeni katman, pattern, paket).
- `development-guide.md` iş akışı değiştiğinde güncellenir (yeni komut, env değişkeni, sorun).
- Büyük mimari karar alındığında kök `docs/decisions/ADR-XXX-<konu>.md` oluşturulur.
- Dokümanlar kod değişikliğiyle aynı commit'te güncellenir; ayrı PR açılmaz.
