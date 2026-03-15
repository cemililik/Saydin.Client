# Saydin.Client — Mimari

## Genel Yapı

Feature-first Clean Architecture + BLoC pattern. Her özellik kendi klasöründe bağımsız olarak bulunur.

```
lib/
├── core/                   ← Uygulamaya özel paylaşılan altyapı
│   ├── constants/          ← AppColors, ApiEndpoints, AppStrings
│   ├── network/            ← Dio client, interceptors, base repository
│   ├── di/                 ← Dependency injection (get_it + injectable)
│   ├── router/             ← go_router route tanımları
│   └── widgets/            ← Uygulamaya özel ortak widget'lar
├── features/
│   ├── what_if/            ← Ana özellik: "ya alsaydım" hesaplama
│   ├── assets/             ← Asset listesi ve arama
│   └── portfolio/          ← Phase 2 scaffold (henüz aktif değil)
└── l10n/
    └── app_tr.arb          ← Tüm UI string'leri (hardcoded string YASAK)
```

## Katman Mimarisi (Her Feature)

```
features/<feature>/
├── data/
│   ├── models/             ← JSON ↔ Dart dönüşümü (fromJson/toJson)
│   └── repositories/       ← Abstract interface'lerin implementasyonu
├── domain/
│   ├── entities/           ← Saf Dart class'ları — Flutter import YOK
│   ├── repositories/       ← Abstract interface'ler (data bağımlılığını tersine çevirir)
│   └── usecases/           ← Tek sorumluluğa sahip iş mantığı sınıfları
└── presentation/
    ├── bloc/               ← BLoC, Event, State
    ├── pages/              ← Tam sayfa widget'lar (route hedefleri)
    └── widgets/            ← Sayfada kullanılan bileşen widget'lar
```

### Bağımlılık Yönü

```
presentation → domain ← data
```

- `data` katmanı `domain` interface'lerini implement eder
- `presentation` katmanı `domain` entity ve use case'lerini kullanır
- `data` ve `presentation` birbirini referans almaz

## BLoC Pattern

Her **sayfa** için bir BLoC. Widget başına BLoC açılmaz.

```
Kullanıcı etkileşimi → Event → BLoC → UseCase → Repository → API
                                BLoC → State → Widget render
```

### Event → State Akışı (what_if örneği)

```
WhatIfCalculateRequested
    → WhatIfLoading
    → WhatIfSuccess(result) / WhatIfFailure(message)
```

### Kural: BLoC sadece Use Case çağırır

```dart
// DOĞRU ✓
on<WhatIfCalculateRequested>((event, emit) async {
  emit(WhatIfLoading());
  final result = await _calculateWhatIf(event.request);  // UseCase
  result.fold(
    (failure) => emit(WhatIfFailure(failure.message)),
    (data) => emit(WhatIfSuccess(data)),
  );
});

// YANLIŞ ✗ — BLoC'ta doğrudan HTTP
on<WhatIfCalculateRequested>((event, emit) async {
  final response = await _dioClient.post('/what-if/calculate', ...);
});
```

## Feature: what_if

Ana özellik. Kullanıcı akışı:

```
AssetSelectionPage → DateRangeSelectionPage → AmountInputPage → ResultPage
```

Her sayfa arası geçiş `go_router` ile yapılır. Hesaplama `WhatIfBloc` tarafından yönetilir.

### Sonuç Gösterimi Kuralları

- **Tutar:** `NumberFormat.currency(locale: 'tr_TR', symbol: '₺')` — örnek: ₺47.010,34
- **Yüzde:** `NumberFormat.decimalPercentPattern(locale: 'tr_TR', decimalDigits: 2)`
- **Tarih:** `DateFormat('dd.MM.yyyy', 'tr_TR')` — örnek: 01.03.2020
- **Kar/zarar rengi:** Yeşil (0xFF2E7D32) veya kırmızı (0xFFC62828), ikona eşlik eder (erişilebilirlik)

## Dependency Injection

`get_it` + `injectable` kullanılır. Her modül kendi DI kaydını `@injectable` annotation'larıyla tanımlar.

```dart
// Kayıt (otomatik generated)
@injectable
class CalculateWhatIf {
  CalculateWhatIf(this._repository);
  final IWhatIfRepository _repository;
}

// Kullanım
final calculateWhatIf = getIt<CalculateWhatIf>();
```

## Navigasyon

`go_router` ile type-safe route tanımları. Tüm route'lar `core/router/` altında merkezi olarak tanımlanır.

## API İstemcisi

`Dio` + interceptor zinciri:

```
İstek → DeviceIdInterceptor → AuthInterceptor → ErrorInterceptor → API
```

- `DeviceIdInterceptor`: Her isteğe `X-Device-ID` header'ı ekler (FlutterSecureStorage'dan UUID)
- `ErrorInterceptor`: HTTP hata kodlarını domain exception'larına dönüştürür
- Base URL: environment config'den gelir, hardcode yasak

## Lokalizasyon

Tüm UI string'leri `l10n/app_tr.arb` dosyasında tanımlanır. `flutter gen-l10n` ile `AppLocalizations` sınıfı üretilir.

```dart
// Kullanım
context.l10n.calculate          // "Hesapla"
context.l10n.loadingResult      // "Sonuç yükleniyor..."
```

Widget'ta hardcoded Türkçe string kesinlikle yasaktır.
