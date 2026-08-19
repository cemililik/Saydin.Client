# Geliştirme Kılavuzu — Saydin.Client

> Android Kotlin/AGP toolchain modernizasyonu şimdilik ertelenmiştir. Karar,
> risk, maliyet, yeniden değerlendirme koşulları ve uygulanacak migration planı
> için [Android Toolchain Modernizasyonu — Ertelenmiş Migration Planı](android-toolchain-migration-plan.md)
> belgesine bakın.

## Ön Koşullar

| Araç | Versiyon | Kontrol |
|---|---|---|
| Flutter | 3.41.4 (kaynak: `pubspec.yaml` `environment.flutter`) | `flutter --version` |
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

# iOS Simulator
flutter run \
  --dart-define=API_BASE_URL=http://localhost:5080 \
  --dart-define=APP_ENV=development

# Fiziksel cihaz: LAN/tunnel endpoint'i HTTPS olmalı
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=https://<dev-host> \
  --dart-define=APP_ENV=development

# Sentry hata izleme etkin (opsiyonel)
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:5080 \
  --dart-define=APP_ENV=development \
  --dart-define=SENTRY_DSN=https://<key>@sentry.io/<project>
```

> `API_BASE_URL` tanımlı değilse uygulama açılışta `StateError` ile çöker
> (fail-loud). Release build'lerde scheme **`https://` zorunludur**; debug
> build'lerde `http://` sadece `localhost` / `127.0.0.1` / `10.0.2.2`
> host'larında kabul edilir. LAN ve tünel origin'leri debug dahil HTTPS
> kullanır (bkz. [lib/core/network/api_base_url_validator.dart](../lib/core/network/api_base_url_validator.dart)).
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

# Fiziksel cihaz (USB debug açık; LAN/tunnel endpoint'i HTTPS olmalı)
flutter run -d <device-id> --dart-define=API_BASE_URL=https://<dev-host> --dart-define=APP_ENV=development

# Profile modda (performans testi; onaylı HTTPS staging origin'i)
flutter run --profile \
  --dart-define=API_BASE_URL=https://<approved-staging-origin> \
  --dart-define=APP_ENV=staging \
  --dart-define=SENTRY_DSN=<staging-dsn>
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
  --dart-define=API_BASE_URL=https://<approved-production-origin> \
  --dart-define=APP_ENV=production \
  --dart-define=SENTRY_DSN=<production-dsn>
# Çıktı: build/ios/ipa/Saydin.ipa
```

### Android

```bash
# Play Store için AAB
flutter build appbundle \
  --dart-define=API_BASE_URL=https://<approved-production-origin> \
  --dart-define=APP_ENV=production \
  --dart-define=SENTRY_DSN=<production-dsn>
# Çıktı: build/app/outputs/bundle/release/app-release.aab

# Debug APK (test dağıtımı)
flutter build apk \
  --dart-define=API_BASE_URL=http://10.0.2.2:5080 \
  --dart-define=APP_ENV=development
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
| `v0.2.0-rc.1` | staging | `internal` (draft) | beta | `staging` (koruma dış konfigürasyonuna bağlı) |
| `v0.2.0` | production | `production` (%10 staged) | beta | `production` (**required reviewer kurulmadan güvenli değildir**) |

### Adım Adım Release

1. **`main` yeşil mi kontrol et** ([Actions sekmesi](https://github.com/cemililik/Saydin.Client/actions)).
2. **Production legal approval commit'ini hazırla:** Önce
   [legal release sign-off](legal/legal-release-signoff.md) belgesindeki sırayı
   tamamla. Dört legal metni nihai hale getir; `--print-bundle-hash` sonucunu
   `LegalAcceptanceVersion.bundleSha256` ile eşleştir; gerekiyorsa legal
   version/document ID/tarihi artır; `--print-runtime-surface-hash` ile
   privacy/runtime snapshot'ını al ve beş gerçek rolün kanıtlı onayını tamamla.
   Final legal/source commit'i bundan sonra approved source SHA olarak sabitle.
   Schema v2 `docs/legal/legal-release-approval.json` içindeki
   `source_commit_sha`, iki hash ve legal version alanlarını o commit'e bağla.
   Ardından tek parent'lı ve source commit'e göre **yalnız
   approval JSON'u değiştiren** ayrı bir commit oluştur; production tag bu
   approval commit'ine konur. RC tag'lerinde bu adım zorunlu değildir.

   ```bash
   python3 tool/verify_legal_release_approval.py --print-bundle-hash
   python3 tool/verify_legal_release_approval.py --print-runtime-surface-hash
   ```

3. **Annotated tag oluştur** — gövdede TR/EN release notes:

   ```bash
   git tag -a v0.2.0 -m "v0.2.0

   ✨ Yeni portföy ekranı eklendi.
   🐛 Grafik render hatası düzeltildi.

   =====LANG_SEPARATOR=====

   ✨ New portfolio screen.
   🐛 Fixed chart rendering bug.
   "
   ```

4. **Tag'i push'la:**
   ```bash
   git push origin v0.2.0
   ```

5. **GitHub Actions takip et:** [release.yml](../.github/workflows/release.yml)
   tetiklenir. Workflow'un `environment: production` demesi tek başına manuel
   onay oluşturmaz. Store secret'ları tanımlanmadan önce GitHub Settings →
   Environments → production altında bağımsız required reviewer, self-review
   yasağı ve tag deployment policy kurulmuş ve ayrıca doğrulanmış olmalıdır.
   Verifier approver kimliğinin gerçekliğini veya hukuk görüşünün yeterliliğini
   kanıtlamaz; agent isim/identity/evidence uyduramaz.

6. **Staged rollout'u büyüt:** Production deployment %10 ile başlar. 24-48 saat sonra crash-free rate sağlamsa Play Console → Production → Manage release → %25 / %50 / %100 promote et.

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

Separator yoksa TR ve EN aynı annotated tag body'yi alır. Karakter limiti Play
Store'un 500'lük sınırı; daha uzun yazarsanız truncate edilir. Lightweight tag
için commit-subject fallback yoktur; workflow fail-closed reddeder.

### Acil Yeniden Çalıştırma

Workflow yarıda kalırsa veya retry gerekirse:

1. GitHub Actions → Release workflow → "Run workflow" butonu
2. `tag` input'una mevcut tag adını gir (`v0.2.0`)
3. Workflow yeniden başlar; `run_attempt` yeni ve store-uyumlu benzersiz build
   numarasına dahil edilir. Concurrency aynı tag için iki release'in eşzamanlı
   ilerlemesini engeller.

### Versiyon Strateji

| Senaryo | Tag |
|---|---|
| Yeni özellik | `v0.2.0` (minor bump) |
| Bug fix | `v0.2.1` (patch bump) |
| Breaking change | `v1.0.0` (major bump) |
| Staging deneme | `v0.2.0-rc.1`, `-rc.2`, ... |

Commit mesajları (Conventional Commits) sürüm seçimine ipucu verir ama otomatik bump'lamaz; final karar tag pushlayan kişiye aittir.

### Yasak

- **Lightweight tag** (`git tag v0.2.0` — `-a` flag'i olmadan): workflow bunu
  fallback uygulamadan reddeder.
- **Push'lanmış tag'i silme/force-update/retarget:** Kesinlikle yasaktır.
  Hatalı pushed tag yerine yeni SemVer; production için ayrı content-bound
  approval commit'i kullan.
- **Main'de olmayan commit'i tag'leme:** Guard job hatayla durdurur — sadece `main`'e merge edilmiş commit'ler release'lenebilir.
- **Onaysız production origin'i:** Validator origin-only HTTPS sözleşmesini
  doğrular; kalıcı staging/production host allowlist'i ve ortam ayrımı SEC-02
  kararıyla ertelenmiştir. Owner doğrulaması olmadan production tag basılmaz.

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
