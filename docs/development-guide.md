# Geliştirme Kılavuzu — Saydin.Client

## Ön Koşullar

| Araç | Versiyon | Kontrol |
|---|---|---|
| Flutter | 3.41.0 | `flutter --version` |
| Dart | 3.x (Flutter ile gelir) | `dart --version` |
| Xcode | 16+ (iOS için) | `xcode-select --print-path` |
| Android Studio | Ladybug+ (Android için) | AVD Manager için |
| CocoaPods | latest (iOS için) | `pod --version` |

```bash
# Ortam doğrulama
flutter doctor
```

## 1. Bağımlılıkları Yükle

```bash
cd src/Saydin.Client
flutter pub get
```

## 2. Lokalizasyon Kodunu Üret

```bash
# app_tr.arb → app_localizations.dart
flutter gen-l10n
```

> Bu adım `app_tr.arb` her değiştiğinde tekrarlanmalıdır. CI'da da zorunludur.

## 3. Ortam Yapılandırması

API adresi ve Sentry DSN `--dart-define` ile enjekte edilir — kaynak koda gömülmez:

```bash
# Android Emülatör (10.0.2.2 = host makinesi)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:5080 \
  --dart-define=APP_ENV=development

# iOS Simulator / fiziksel cihaz
flutter run \
  --dart-define=API_BASE_URL=http://localhost:5080 \
  --dart-define=APP_ENV=development

# Sentry hata izleme etkin (opsiyonel)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:5080 \
  --dart-define=APP_ENV=development \
  --dart-define=SENTRY_DSN=https://<key>@sentry.io/<project>
```

> `API_BASE_URL` tanımlı değilse varsayılan `http://10.0.2.2:5080` kullanılır.
> `SENTRY_DSN` tanımlı değilse Sentry sessizce devre dışı kalır.

## 4. Uygulamayı Çalıştır

```bash
# Bağlı cihazları listele
flutter devices

# Android Emülatör
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080

# iOS Simulator
flutter run -d "iPhone 16" --dart-define=API_BASE_URL=http://localhost:5080

# Fiziksel cihaz (USB debug açık)
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<local-ip>:5080

# Release modda (performans testi)
flutter run --release --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

## 5. Testleri Çalıştır

```bash
# Önce l10n kodu üret
flutter gen-l10n

# Tüm testler
flutter test

# Coverage raporu ile
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Belirli test dosyası
flutter test test/core/error/dio_error_mapper_test.dart
```

## 6. Kod Kalitesi

```bash
# Analiz (--fatal-infos CI ile aynı kural)
flutter analyze --fatal-infos

# Format kontrolü (CI ile aynı)
dart format --output=none --set-exit-if-changed lib/ test/

# Format uygula
dart format lib/ test/
```

## 7. Build

### iOS

```bash
# TestFlight için IPA
flutter build ipa \
  --dart-define=API_BASE_URL=https://api.saydin.app \
  --dart-define=APP_ENV=production \
  --dart-define=SENTRY_DSN=<production-dsn>
# Çıktı: build/ios/ipa/Saydin.ipa
```

### Android

```bash
# Play Store için AAB
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.saydin.app \
  --dart-define=APP_ENV=production \
  --dart-define=SENTRY_DSN=<production-dsn>
# Çıktı: build/app/outputs/bundle/release/app-release.aab

# Debug APK (test dağıtımı)
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

## 8. Sık Kullanılan Komutlar

```bash
# Paketleri güncelle
flutter pub upgrade

# Cache temizle (sorun çözme)
flutter clean && flutter pub get && flutter gen-l10n

# Tüm bağımlılıkları gözden geçir
flutter pub outdated
```

## 9. Yeni Feature Ekleme

1. `lib/features/<feature_name>/` dizinini oluştur
2. Katmanları oluştur: `data/models/`, `data/repositories/`, `domain/entities/`, `domain/repositories/`, `domain/usecases/`, `presentation/bloc/`, `presentation/pages/`, `presentation/widgets/`
3. Domain entity'sini yaz (Flutter import'suz saf Dart)
4. Repository interface'ini domain katmanına ekle
5. Data modelini ve repository implementasyonunu yaz
6. Use case yaz
7. BLoC, Event, State yaz — state'lerde `AppError` kullan, string mesaj **yok**
8. Widget'ta hata mesajını `switch(state.error)` + `context.l10n.errorXxx` ile çöz
9. `lib/core/di/injection.dart` dosyasına DI kayıtlarını ekle
10. Yeni string'leri `lib/l10n/app_tr.arb`'a ekle, `flutter gen-l10n` çalıştır
11. Birim testleri yaz (`test/features/<feature_name>/`)

## 10. Lokalizasyon Ekleme

`lib/l10n/app_tr.arb` dosyasını düzenle:

```json
{
  "@@locale": "tr",
  "myNewKey": "Yeni metin",
  "myParamKey": "{amount} TL yatırım",
  "@myParamKey": {
    "placeholders": {
      "amount": {"type": "String"}
    }
  }
}
```

Ardından kodu üret:
```bash
flutter gen-l10n
```

Kullanım:
```dart
context.l10n.myNewKey
context.l10n.myParamKey(amount: '10.000')
```

## 11. Yaygın Sorunlar

### `flutter gen-l10n` sonrası derleme hatası

```bash
flutter clean && flutter pub get && flutter gen-l10n
```

### iOS CocoaPods sorunu

```bash
cd ios && pod install --repo-update && cd ..
```

### Android emülatörde backend'e bağlanılamıyor

`localhost` yerine `10.0.2.2` kullan:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

### `flutter analyze` lint hatası

CI ile aynı kuralları çalıştır:
```bash
flutter analyze --fatal-infos
```
