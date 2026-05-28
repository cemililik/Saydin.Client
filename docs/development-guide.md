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

## 2. Git Hook'larını Etkinleştir

```bash
git config core.hooksPath .githooks
```

Bu komut bir kez çalıştırılır. Sonrasında her `git commit`'te otomatik olarak:
- `dart format` format kontrolü yapılır
- `flutter analyze` analizi çalışır

Commit format hatası verirse: `dart format lib/ test/` çalıştırıp tekrar commit edin.

## 2. Lokalizasyon Kodunu Üret

```bash
# app_tr.arb + app_en.arb → app_localizations.dart, app_localizations_tr.dart, app_localizations_en.dart
flutter gen-l10n
```

> Bu adım `app_tr.arb` veya `app_en.arb` her değiştiğinde tekrarlanmalıdır. CI'da da zorunludur.

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

> `API_BASE_URL` tanımlı değilse uygulama açılışta `StateError` ile çöker
> (fail-loud). Release build'lerde scheme **`https://` zorunludur**; debug
> build'lerde `http://` sadece `localhost` / `127.0.0.1` / `10.0.2.2` veya
> `*.ngrok-free.app` / `*.ngrok.app` / `*.trycloudflare.com` host'larında
> kabul edilir (bkz. [lib/core/network/api_base_url_validator.dart](../lib/core/network/api_base_url_validator.dart)).
>
> `SENTRY_DSN` tanımlı değilse Sentry sessizce devre dışı kalır.
>
> **Certificate pinning** (opsiyonel): release build'lerde MITM riskine karşı
> `--dart-define=PINNED_CERT_SHA256=<hex,hex>` ile primary + backup
> sertifika SHA-256 fingerprint'leri pinlenebilir. Pin yoksa sistem trust
> store kullanılır — dev ortamı bozulmaz. Pin hesaplaması:
> `openssl x509 -in cert.pem -outform DER | openssl dgst -sha256`.

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
10. Yeni string'leri `lib/l10n/app_tr.arb` ve `lib/l10n/app_en.arb`'a ekle, `flutter gen-l10n` çalıştır
11. Birim testleri yaz (`test/features/<feature_name>/`)

## 10. Lokalizasyon Ekleme

**Desteklenen diller:** Türkçe (`tr`, varsayılan), İngilizce (`en`)

Her iki ARB dosyasını birlikte düzenle:

**`lib/l10n/app_tr.arb`:**
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

**`lib/l10n/app_en.arb`:**
```json
{
  "@@locale": "en",
  "myNewKey": "New text",
  "myParamKey": "{amount} TRY investment",
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

> **Önemli:** `app_tr.arb`'a eklenen her key `app_en.arb`'a da eklenmelidir. Eksik key derleme hatasına neden olur.

### Backend Lokalizasyonu

Backend'de de lokalize edilmesi gereken metin varsa (hata mesajı, asset ismi vb.) `.resx` dosyalarını güncelle:
- `src/Saydin.Api/Resources/ErrorMessages.resx` — Türkçe
- `src/Saydin.Api/Resources/ErrorMessages.en.resx` — İngilizce

## 11. Release Çıkarma (Tag-Driven)

Saydın **tag-driven release** modelini kullanır — sadece `v*` formatında annotated tag push'lamak Play Store + TestFlight + GitHub Release'i tetikler. `main`'e push tek başına release yapmaz.

### Kanallar

| Tag formatı | Kanal | Play Store | TestFlight | GitHub Environment |
|---|---|---|---|---|
| `v0.2.0-rc.1` | staging | `internal` (draft) | beta | `staging` (oto-onay) |
| `v0.2.0` | production | `production` (%10 staged) | beta | `production` (**manuel approval**) |

### Adım Adım Release

1. **`main` yeşil mi kontrol et** ([Actions sekmesi](https://github.com/cemililik/Saydin.Client/actions)).
2. **Annotated tag oluştur** — gövdede TR/EN release notes:

   ```bash
   git tag -a v0.2.0 -m "v0.2.0

   ✨ Yeni portföy ekranı eklendi.
   🐛 Grafik render hatası düzeltildi.

   =====LANG_SEPARATOR=====

   ✨ New portfolio screen.
   🐛 Fixed chart rendering bug.
   "
   ```

3. **Tag'i push'la:**
   ```bash
   git push origin v0.2.0
   ```

4. **GitHub Actions takip et:** [release.yml](../.github/workflows/release.yml) tetiklenir. Production tag ise `production` environment manuel onay bekler — onaylayıcılar GitHub Settings → Environments → production altında tanımlı.

5. **Staged rollout'u büyüt:** Production deployment %10 ile başlar. 24-48 saat sonra crash-free rate sağlamsa Play Console → Production → Manage release → %25 / %50 / %100 promote et.

### Tag Mesajı Formatı

```
v0.2.0                          ← Tag subject (GitHub Release başlığı)
                                ← Boş satır
<Türkçe release notes>           ← Play Store TR + TestFlight TR (≤500)
                                ← Boş satır
=====LANG_SEPARATOR=====         ← Ayraç
                                ← Boş satır
<English release notes>          ← Play Store EN-US + TestFlight EN (≤500)
```

Separator yoksa TR ve EN aynı metni alır. Karakter limiti Play Store'un 500'lük sınırı; daha uzun yazarsanız truncate edilir.

### Acil Yeniden Çalıştırma

Workflow yarıda kalırsa veya retry gerekirse:

1. GitHub Actions → Release workflow → "Run workflow" butonu
2. `tag` input'una mevcut tag adını gir (`v0.2.0`)
3. Workflow yeniden başlar (concurrency=false sayesinde başkasıyla çakışmaz)

### Versiyon Strateji

| Senaryo | Tag |
|---|---|
| Yeni özellik | `v0.2.0` (minor bump) |
| Bug fix | `v0.2.1` (patch bump) |
| Breaking change | `v1.0.0` (major bump) |
| Staging deneme | `v0.2.0-rc.1`, `-rc.2`, ... |

Commit mesajları (Conventional Commits) sürüm seçimine ipucu verir ama otomatik bump'lamaz; final karar tag pushlayan kişiye aittir.

### Yasak

- **Lightweight tag** (`git tag v0.2.0` — `-a` flag'i olmadan): annotated message yok, fallback son commit subject'i olur.
- **Tag silip yeniden push:** Play Console'da çift sürüm. Yeni sürüm gerekirse `v0.2.1` olarak çıkar.
- **Main'de olmayan commit'i tag'leme:** Guard job hatayla durdurur — sadece `main`'e merge edilmiş commit'ler release'lenebilir.

## 12. Yaygın Sorunlar

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
