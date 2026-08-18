---
name: bloc-page
description: Create a single new page with BLoC + Event + State + page widget + test file, wired into an existing feature. Use when adding a page to an already-scaffolded feature (not creating a new feature from scratch — for that use feature-scaffold), or when user says "yeni sayfa ekle", "new page with bloc", "bloc page".
---

Mevcut bir feature'ın `presentation/` altına yeni bir sayfa + BLoC + test üretir.

Hata akışında kanonik [financial/error contract](../../../docs/engineering/financial-error-contract.md) zorunludur: use case `Future<T>` döndürür ve typed `AppError` fırlatır.

> Sıfırdan yeni feature için bu skill DEĞİL — [feature-scaffold](../feature-scaffold/SKILL.md) kullan. Bu skill sadece mevcut feature'a yeni sayfa eklemek için.

## Önce sor

1. **Hangi feature'a ekleniyor?** (örn. `lib/features/portfolio/`)
2. **Sayfa adı** (snake_case, örn. `portfolio_summary`)
3. **Use case** zaten var mı, yoksa yeni use case mı gerekiyor?
4. **Form input** var mı? (kullanıcının doldurduğu alanlar — state'in içinde tutulacak)

## Üretilecek dosyalar

```
lib/features/<feature>/presentation/
├── bloc/
│   ├── <page>_bloc.dart
│   ├── <page>_event.dart
│   └── <page>_state.dart
└── pages/<page>_page.dart

test/features/<feature>/presentation/bloc/
└── <page>_bloc_test.dart
```

## BLoC iskeleti

```dart
// <page>_bloc.dart
class PortfolioSummaryBloc extends Bloc<PortfolioSummaryEvent, PortfolioSummaryState> {
  PortfolioSummaryBloc(this._fetchSummary) : super(const PortfolioSummaryState()) {
    on<PortfolioSummaryRequested>(_onRequested);
  }

  final FetchPortfolioSummary _fetchSummary;

  Future<void> _onRequested(
    PortfolioSummaryRequested event,
    Emitter<PortfolioSummaryState> emit,
  ) async {
    emit(state.copyWith(status: PortfolioSummaryStatus.loading));
    try {
      final data = await _fetchSummary(event.params);
      emit(state.copyWith(
        status: PortfolioSummaryStatus.success,
        data: data,
        error: null,
      ));
    } on AppError catch (error) {
      emit(state.copyWith(
        status: PortfolioSummaryStatus.failure,
        error: error,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: PortfolioSummaryStatus.failure,
        error: UnknownError(cause: error),
      ));
    }
  }
}
```

## State iskeleti

```dart
enum PortfolioSummaryStatus { initial, loading, success, failure }

class PortfolioSummaryState extends Equatable {
  const PortfolioSummaryState({
    this.status = PortfolioSummaryStatus.initial,
    this.data,
    this.error,
    // Form input alanları — hata geldiğinde de korunur:
    this.selectedPeriod = SummaryPeriod.month,
  });

  final PortfolioSummaryStatus status;
  final PortfolioSummary? data;
  final AppError? error;
  final SummaryPeriod selectedPeriod;

  PortfolioSummaryState copyWith({
    PortfolioSummaryStatus? status,
    PortfolioSummary? data,
    AppError? error,
    SummaryPeriod? selectedPeriod,
  }) {
    return PortfolioSummaryState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  @override
  List<Object?> get props => [status, data, error, selectedPeriod];
}
```

## Page iskeleti

```dart
class PortfolioSummaryPage extends StatelessWidget {
  const PortfolioSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PortfolioSummaryBloc>(
      create: (_) => sl<PortfolioSummaryBloc>()
        ..add(const PortfolioSummaryRequested()),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.portfolioSummaryTitle)),
        body: BlocConsumer<PortfolioSummaryBloc, PortfolioSummaryState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == PortfolioSummaryStatus.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!.localizedMessage(context.l10n)),
              ),
            );
          },
          builder: (context, state) => switch (state.status) {
            PortfolioSummaryStatus.initial => const _Empty(),
            PortfolioSummaryStatus.loading => const _Loading(),
            // success state'inde data null olamaz — BLoC garantisi
            PortfolioSummaryStatus.success => _Body(data: state.data!),
            // failure state'inde error null olamaz — BLoC garantisi
            PortfolioSummaryStatus.failure => _Failure(error: state.error!),
          },
        ),
      ),
    );
  }
}
```

`switch (state.status)` Dart 3 pattern syntax'ı — exhaustive olmazsa analyzer hata verir.

## Test iskeleti

```dart
void main() {
  late MockFetchPortfolioSummary mockUseCase;

  setUp(() {
    mockUseCase = MockFetchPortfolioSummary();
  });

  blocTest<PortfolioSummaryBloc, PortfolioSummaryState>(
    'success: loading → success',
    setUp: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => fixtureSummary,
      );
    },
    build: () => PortfolioSummaryBloc(mockUseCase),
    act: (b) => b.add(const PortfolioSummaryRequested()),
    expect: () => [
      isA<PortfolioSummaryState>()
        .having((s) => s.status, 'status', PortfolioSummaryStatus.loading),
      isA<PortfolioSummaryState>()
        .having((s) => s.status, 'status', PortfolioSummaryStatus.success)
        .having((s) => s.data, 'data', fixtureSummary),
    ],
  );

  blocTest<PortfolioSummaryBloc, PortfolioSummaryState>(
    'failure: loading → failure',
    setUp: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => throw const NoInternetError(),
      );
    },
    build: () => PortfolioSummaryBloc(mockUseCase),
    act: (b) => b.add(const PortfolioSummaryRequested()),
    expect: () => [
      isA<PortfolioSummaryState>()
        .having((s) => s.status, 'status', PortfolioSummaryStatus.loading),
      isA<PortfolioSummaryState>()
        .having((s) => s.status, 'status', PortfolioSummaryStatus.failure),
    ],
  );
}
```

## DI kaydı

```dart
// lib/core/di/injection.dart — Presentation BLoCs bölümüne ekle
sl.registerFactory(() => PortfolioSummaryBloc(sl()));
```

`registerFactory` — her sayfa girişinde yeni instance (state leakage olmasın).

## Yapılması gerekenler

- [ ] BLoC + Event + State üret
- [ ] Page widget üret (BlocProvider + BlocConsumer)
- [ ] DI'da `registerFactory` ekle
- [ ] L10n key'leri TR+EN ekle (bkz. [l10n-add](../l10n-add/SKILL.md))
- [ ] Test dosyası — happy + sad path minimum
- [ ] `flutter analyze --fatal-infos` yeşil
- [ ] `flutter test test/features/<feature>/presentation/bloc/<page>_bloc_test.dart` yeşil

## Yasak

- `setState` — bu BLoC kullanan sayfa, asla
- BLoC içinde HTTP — `final ApiClient _api;` YOK
- Descendant widget içinde `sl<XBloc>()` direkt çağrısı. Composition
  root'taki `BlocProvider.create` callback'i `sl()` kullanabilir; alt widget'lar
  `context.read<XBloc>()` / `BlocBuilder` kullanır.
- State'in içinde fonksiyon alanı tutma — `Equatable` props'la uyumsuz
