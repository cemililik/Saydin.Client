# Saydin Client

Flutter 3.41.4 ile geliştirilmiş Saydın mobil uygulaması (iOS + Android).

## Kurulum

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080 --dart-define=APP_ENV=development
```

## Ağ geliştirme runbook'u

`API_BASE_URL` her zaman `--dart-define` ile verilir; uygulama boş veya
geçersiz bir değerde ilk ağ ekranını beklemeden başlangıçta durur.

- Debug cleartext HTTP yalnızca `localhost`, `127.0.0.1` ve Android emulator
  host loopback'i `10.0.2.2` için açıktır. Bu liste Dart doğrulaması ile
  Android debug network security yapılandırmasının ortak sözleşmesidir.
- iOS Simulator yerel servis için `localhost` kullanabilir. Fiziksel cihazda
  `localhost` cihazın kendisidir; geliştirme makinesine ulaşmak için TLS'li LAN
  origin'i veya HTTPS tüneli kullanın.
- ngrok/cloudflared ve LAN origin'leri **yalnız HTTPS** kullanır; HTTP tünel
  URL'si desteklenmez.
- Profile/release build'lerde HTTP tamamen kapalıdır; release URL authority
  doğrulaması build başlangıcında uygulanır.

Örnekler:

```bash
# Android emulator'da yerel backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080

# iOS Simulator'da yerel backend
flutter run --dart-define=API_BASE_URL=http://localhost:5080

# Fiziksel cihaz veya tünel: HTTPS zorunlu
flutter run --dart-define=API_BASE_URL=https://<güvenilir-dev-origin>
```

## Mimari

Feature-first Clean Architecture + BLoC. Detaylar: [CLAUDE.md](CLAUDE.md)
