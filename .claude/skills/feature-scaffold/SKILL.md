---
name: feature-scaffold
description: Scaffold a new feature in lib/features/<name>/ with CLAUDE.md-compliant data/domain/presentation layers — entity, repository (abstract + impl), use case, BLoC + Event/State, page, DI registration, l10n key placeholders, and test skeletons. Use when user says "yeni özellik ekle", "feature scaffold", "yeni feature oluştur", or asks to start a new feature.
---

Saydın'a yeni bir feature eklemek için **CLAUDE.md'deki katman düzenine** birebir uyan iskelet üret.

## Önce sor (sırayla, tek tek)

1. **Feature adı** (snake_case, örn. `inflation_compare`)
2. **Bir cümlelik amaç** (örn. "Enflasyona göre farklı varlıklar arasında getiri karşılaştırması")
3. **API endpoint** var mı? (varsa path + HTTP method)
4. **BLoC mu Cubit mi?** Page-state taşıyorsa BLoC, tek değer tutuyorsa Cubit
5. **L10n key prefix'i** (örn. `inflationCompare`)

Belirsiz cevap geldiğinde [grill-me](../grill-me/SKILL.md) skill'inin tarzıyla daha fazla sorgula — ama bu skill çalışırken sadece bu feature kapsamında kal.

## Klasör yapısı (CLAUDE.md ile birebir)

```
lib/features/<feature>/
├── data/
│   ├── models/<feature>_response_model.dart       (fromJson — JSON sözleşmesi)
│   └── repositories/<feature>_repository_impl.dart
├── domain/
│   ├── entities/<feature>_result.dart             (saf Dart, Flutter import YOK)
│   ├── repositories/<feature>_repository.dart     (abstract)
│   └── usecases/calculate_<feature>.dart          (callable class — `call()` metodu)
└── presentation/
    ├── bloc/
    │   ├── <feature>_bloc.dart                    (BLoC seçtiyse)
    │   ├── <feature>_event.dart
    │   └── <feature>_state.dart
    ├── pages/<feature>_page.dart
    └── widgets/                                   (sayfa-iç widget'lar burada)
```

## İskelet üretimi sırasında uy

- **Domain entity:** `Equatable` ile genişlet, alanları `final`, `props` tanımla. Para alanları `num` (asla `double`). `import 'package:flutter/...'` YASAK.
- **Repository interface:** `Future<Result<Entity, AppError>>` döndüren metotlar.
- **Repository impl:** `injectable` değil; manuel — `lib/core/di/injection.dart`'a `sl.registerLazySingleton<IFooRepo>(() => FooRepoImpl(sl()));` satırı ekle.
- **Use case:** Tek metot (`call`), tek sorumluluk. `FailureOrSuccess<T>` döndür.
- **BLoC:** Use case'i `final` alan olarak tut. Event handler'lar `emit(state.copyWith(status: loading))` → use case → `emit(state.copyWith(status: success, data: ...))` deseni.
- **State:** `<feature>_status.dart` enum'u (`initial`, `loading`, `success`, `failure`) + `copyWith`. Form input alanları state'in içinde — hata geldiğinde kullanıcı verisi kaybolmaz.
- **Page:** `BlocProvider<XBloc>(create: (_) => sl(), child: ...)`. `BlocConsumer` ile state'i dinle, `listenWhen` race önler.
- **L10n:** Yeni key'leri **hem `lib/l10n/app_tr.arb` hem `lib/l10n/app_en.arb`** dosyalarına ekle. Placeholder varsa her iki dosyada da tanımla. `flutter gen-l10n` çalıştır.

Detay için [l10n-add](../l10n-add/SKILL.md) skill'ini kullan.

## DI kaydı

`lib/core/di/injection.dart` dosyasında ilgili bölüme ekle:

```dart
// Repositories
sl.registerLazySingleton<IFooRepository>(
  () => FooRepositoryImpl(sl<ApiClient>()),
);

// Use cases
sl.registerLazySingleton(() => CalculateFoo(sl()));

// BLoCs — factory (her sayfaya yeni instance)
sl.registerFactory(() => FooBloc(sl()));
```

## Test iskeletleri

```
test/features/<feature>/
├── data/repositories/<feature>_repository_impl_test.dart  (mocktail ile)
├── domain/usecases/calculate_<feature>_test.dart           (bloc_test gerek yok)
└── presentation/bloc/<feature>_bloc_test.dart              (blocTest)
```

`blocTest` formatı:
```dart
blocTest<FooBloc, FooState>(
  'success path',
  setUp: () {
    when(() => mockUseCase(any())).thenAnswer((_) async => Result.ok(fixture));
  },
  build: () => FooBloc(mockUseCase),
  act: (b) => b.add(FooRequested(...)),
  expect: () => [
    isA<FooState>().having((s) => s.status, 'status', FooStatus.loading),
    isA<FooState>().having((s) => s.status, 'status', FooStatus.success),
  ],
);
```

## Bitirmeden önce

- [ ] `flutter pub get`
- [ ] `flutter gen-l10n`
- [ ] `flutter analyze --fatal-infos` — sıfır error/info
- [ ] `flutter test test/features/<feature>/` — yeşil
- [ ] `git status` ile değişiklikleri özetle, commit atmadan kullanıcıya sun

## Yasak (CLAUDE.md ile aynı, hatırlatma)

- Domain'de `import 'package:flutter/...'`
- Widget içinde HTTP çağrısı
- `setState` (BLoC kullanan sayfada)
- Hardcoded string / renk / URL
- `print()` (`debugPrint` kullan)
- `double` para tutarı için

Yasak ihlali şüphesi varsa [yasak-check](../yasak-check/SKILL.md) skill'i ile diff'i denetle.
