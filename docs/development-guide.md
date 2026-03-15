# Geliştirme Kılavuzu — Saydin.Client

## Ön Koşullar

| Araç | Versiyon | Kontrol |
|---|---|---|
| Flutter | 3.41.0 | `flutter --version` |
| Dart | 3.x (Flutter ile gelir) | `dart --version` |
| Xcode | 15+ (iOS için) | `xcode-select --print-path` |
| Android Studio | Koala+ (Android için) | |
| CocoaPods | latest (iOS için) | `pod --version` |

```bash
# Flutter kurulum doğrulama
flutter doctor
```

## 1. Bağımlılıkları Yükle

```bash
cd src/Saydin.Client
flutter pub get
```

## 2. Kodu Üret (Code Generation)

```bash
# Localization dosyaları (AppLocalizations)
flutter gen-l10n

# DI kodu (injectable)
dart run build_runner build --delete-conflicting-outputs
```

> Bu adım her yeni dosya eklendiğinde veya `@injectable` annotation değiştiğinde tekrarlanmalıdır.

## 3. Ortam Yapılandırması

Backend API URL'sini `--dart-define` ile geçir — hardcoded URL yasaktır:

```bash
# Geliştirme (yerel backend)
flutter run --dart-define=API_BASE_URL=http://localhost:5000

# iOS Simulator
flutter run -d "iPhone 16" --dart-define=API_BASE_URL=http://localhost:5000

# Android Emulator (localhost yerine 10.0.2.2)
flutter run -d "Pixel_8" --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Kod içinde kullanım:
```dart
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');
```

## 4. Uygulamayı Çalıştır

```bash
# Bağlı cihazları listele
flutter devices

# Varsayılan cihazda çalıştır
flutter run --dart-define=API_BASE_URL=http://localhost:5000

# Release modda çalıştır (performans testi için)
flutter run --release --dart-define=API_BASE_URL=http://localhost:5000
```

## 5. Testleri Çalıştır

```bash
# Tüm testler
flutter test

# Belirli test dosyası
flutter test test/features/what_if/bloc/what_if_bloc_test.dart

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 6. Build

### iOS

```bash
# TestFlight için
flutter build ipa --dart-define=API_BASE_URL=https://api.saydin.app
# Çıktı: build/ios/ipa/Saydin.ipa

# Simülatör için
flutter build ios --simulator --dart-define=API_BASE_URL=http://localhost:5000
```

### Android

```bash
# Play Store için AAB
flutter build appbundle --dart-define=API_BASE_URL=https://api.saydin.app
# Çıktı: build/app/outputs/bundle/release/app-release.aab

# APK (test dağıtımı)
flutter build apk --dart-define=API_BASE_URL=https://api.saydin.app
```

## 7. Sık Kullanılan Komutlar

```bash
# Analiz (linting)
flutter analyze

# Format
dart format lib/ test/

# Paketleri güncelle
flutter pub upgrade

# Cache temizle (sorun çözme)
flutter clean && flutter pub get

# Widget test'te golden güncelle
flutter test --update-goldens
```

## 8. Proje Yapısına Yeni Özellik Ekleme

1. `lib/features/<feature_name>/` dizinini oluştur
2. Alt dizinleri oluştur: `data/models/`, `data/repositories/`, `domain/entities/`, `domain/repositories/`, `domain/usecases/`, `presentation/bloc/`, `presentation/pages/`, `presentation/widgets/`
3. Domain entity'sini yaz (Flutter import'suz saf Dart)
4. Repository interface'ini domain katmanına ekle
5. Data modelini ve repository implementasyonunu yaz
6. Use case yaz
7. BLoC, Event, State yaz
8. Sayfayı `core/router/` içine kaydet
9. DI kaydını `@injectable` ile ekle, `build_runner` çalıştır
10. Yeni string'leri `l10n/app_tr.arb`'a ekle, `flutter gen-l10n` çalıştır

## 9. Localization Ekleme

```bash
# l10n/app_tr.arb dosyasını düzenle, ardından:
flutter gen-l10n
```

`app_tr.arb` örneği:
```json
{
  "@@locale": "tr",
  "calculate": "Hesapla",
  "loadingResult": "Sonuç yükleniyor...",
  "profitMessage": "{amount} kazanç ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": {"type": "String"},
      "percent": {"type": "String"}
    }
  }
}
```

## 10. Yaygın Sorunlar

### `flutter gen-l10n` sonrası hata

```bash
flutter clean
flutter pub get
flutter gen-l10n
```

### iOS CocoaPods sorunu

```bash
cd ios && pod install --repo-update && cd ..
```

### build_runner çakışması

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Android emülatörde backend'e bağlanılamıyor

Android emülatörde `localhost` yerine `10.0.2.2` kullan:
```bash
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:5000
```
