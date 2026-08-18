---
name: device-deploy
description: Deploy the Flutter app to an explicitly selected physical iOS device with a session-provided API origin. Defaults to debug unless the user explicitly requests another mode; verifies device discovery and endpoint inputs before running.
---

Saydın'ı fiziksel iOS cihaza deploy eder. Committed dosyada cihaz kimliği,
kişisel cihaz adı veya geçici backend/tünel URL'si tutulmaz.

## Zorunlu girdiler

1. **Mod:** Kullanıcı açıkça istemedikçe `debug`.
2. **Device ID:** O oturumdaki `flutter devices` çıktısından seçilir veya
   ignore edilen yerel `SAYDIN_DEVICE_ID` ortam değişkeninden okunur.
3. **API origin:** Kullanıcının bu oturum için verdiği değer veya ignore
   edilen yerel `SAYDIN_API_BASE_URL` ortam değişkeni. Default yoktur.
4. **APP_ENV:** `development` veya onaylı test ortamı; API origin ile aynı
   ortama ait olduğu doğrulanır.

Bir girdi eksikse fail-closed dur ve yalnız eksik girdiyi iste. Log veya rapora
origin'in query/credential parçasını yazma.

## Preflight

```bash
flutter devices

DEVICE_ID_ARG="${SAYDIN_DEVICE_ID:?SAYDIN_DEVICE_ID must be set locally}"
API_BASE_URL_ARG="${SAYDIN_API_BASE_URL:?SAYDIN_API_BASE_URL must be set locally}"
APP_ENV_ARG="${SAYDIN_APP_ENV:-development}"

case "$API_BASE_URL_ARG" in
  https://*) ;;
  *) echo "Physical-device API origin must use HTTPS" >&2; exit 1 ;;
esac

case "$APP_ENV_ARG" in
  development|staging) ;;
  *) echo "Unapproved deploy environment" >&2; exit 1 ;;
esac
```

- `flutter devices` sonucunda `DEVICE_ID_ARG` tam olarak bir bağlı cihazla
  eşleşmelidir. Eşleşmiyorsa komutu çalıştırma.
- Geçici tünel kullanılıyorsa origin oturumda yeniden doğrulanır ve HTTPS
  olmalıdır. Eski session/commit değeri tekrar kullanılmaz.
- Backend'in belgelenmiş health/environment identity endpoint'i varsa deploy
  öncesi `curl --fail` ile kontrol et. Repoda olmayan endpoint'i uydurma.
- Release/profile için geçici tünel kabul etme; maintainer tarafından onaylı,
  sahipliği doğrulanmış test origin'i gerekir.

## Çalıştırma

Debug:

```bash
flutter run \
  --device-id "$DEVICE_ID_ARG" \
  --dart-define="API_BASE_URL=$API_BASE_URL_ARG" \
  --dart-define="APP_ENV=$APP_ENV_ARG"
```

Kullanıcı açıkça profile/release isterse aynı doğrulanmış argümanlara
ilgili Flutter flag'i eklenir. Komut arka plana shell `&` ile atılmaz; runtime
foreground/background yönetimi sağlıyorsa onun kontrollü mekanizması kullanılır.

## Simulator/emulator ayrımı

- iOS Simulator yerel backend için `http://localhost:<port>` kullanabilir.
- Android emulator host loopback'i `http://10.0.2.2:<port>` kullanabilir.
- Fiziksel cihazda `localhost` cihazın kendisidir; fiziksel cihaz origin'i HTTPS
  olmalıdır.

## Sorun giderme

- **Device not found:** USB/Wi-Fi pairing, trust onayı ve Xcode Devices and
  Simulators ekranını kontrol et; başka bir cihaza otomatik fallback yapma.
- **Code signing:** `ios/Runner.xcworkspace` için doğru development team'i
  seç; signing kontrolünü bypass etme.
- **Endpoint erişilemiyor:** Oturum değerini kaynağından yeniden al. Repo
  dosyasına güncel URL veya cihaz ID'si yazma.

## Yasak

- Hardcoded/varsayılan device ID, cihaz adı veya tünel URL'si
- Kullanıcı istemeden release/profile modu
- Fiziksel cihazda localhost/127.0.0.1
- Device/API preflight başarısızken deploy
- Secret, query string veya credential içeren origin'i loglamak
