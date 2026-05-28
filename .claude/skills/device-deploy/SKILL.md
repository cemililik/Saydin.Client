---
name: device-deploy
description: Deploy the Flutter app to the physical test iPhone "C.I." (device ID 00008101-00013C6A02B9003A) with the correct ngrok API URL, defaulting to debug mode unless user explicitly requests release. Verifies device connectivity first. Use when user says "iPhone'a gönder", "cihaza deploy", "deploy iphone", "telefonda çalıştır", "cihaza yükle".
---

Saydın'ın test iPhone'una (C.I., iOS 18.6) doğru `--dart-define` ve `--device-id` parametreleriyle deploy eder.

## Sabitler (CLAUDE.md'den)

| | |
|---|---|
| Cihaz adı | iPhone "C.I." |
| Device ID | `00008101-00013C6A02B9003A` |
| API URL (aktif backend) | `https://fumed-cleverishly-moses.ngrok-free.dev/` |
| Varsayılan mod | **Debug** (kullanıcı açıkça "release" demedikçe) |

## Önce sor

1. **Mod**: Debug (varsayılan) mı, Release mı? Performans testi gerekiyorsa Release; aksi halde Debug.
2. **API URL** (opsiyonel): Yukarıdaki ngrok URL'i mi, başka bir endpoint mi? (Genelde aynı kalır.)
3. **Hot reload izlemesi gerekiyor mu?** Foreground'da çalışsın yoksa arkaplana mı atsın?

## İş akışı

1. **Cihaz bağlı mı kontrol et:**
   ```bash
   flutter devices
   ```
   `00008101-00013C6A02B9003A` listede yoksa:
   - USB bağlantısını kontrol et
   - Xcode'da "Trust this computer" onayı gerekebilir
   - `idevice_id -l` ile alternatif kontrol

2. **Çalıştır (debug — varsayılan):**
   ```bash
   flutter run \
     --dart-define=API_BASE_URL=https://fumed-cleverishly-moses.ngrok-free.dev/ \
     --device-id 00008101-00013C6A02B9003A
   ```

3. **Çalıştır (release — performans testi):**
   ```bash
   flutter run \
     --dart-define=API_BASE_URL=https://fumed-cleverishly-moses.ngrok-free.dev/ \
     --device-id 00008101-00013C6A02B9003A \
     --release
   ```

4. **Background'da çalıştırma:** Eğer hot reload izlemek istemiyorsan ve sadece deploy edip kapatmak istiyorsan komuta `&` ekleme — Flutter run terminale bağlı kalır. `run_in_background: true` ile Bash tool kullanmak en pratiği.

## Sorun giderme

**"Multiple devices found" hatası:** `--device-id` parametresi olmadan çalıştırıyorsun, ekle.

**"Device not found":** USB bağlantısını sök/tak, Xcode'u aç ve "Window → Devices and Simulators" altında cihazın güvenildiğinden emin ol.

**iOS code signing hatası (debug'da bile):**
- Xcode → `ios/Runner.xcworkspace` aç
- "Signing & Capabilities" → Team seç
- Bir kez Xcode üzerinden build alıp sonra `flutter run` ile devam

**Ngrok URL süresi dolmuş / değişmiş:** CLAUDE.md'deki URL'i güncel olmayabilir; aktif URL için backend ekibine sor veya `https://dashboard.ngrok.com` kontrol et. Geçici çözüm: emülatör için `http://10.0.2.2:5080`, simulator için `http://localhost:5080`.

**Hot reload çalışmıyor / hot restart gerekiyor:** Hot reload `r`, hot restart `R` (büyük). Native değişiklik yaptıysan `R` gerekir.

## Alternatif cihazlar

Başka cihaza deploy gerekirse:

```bash
# Tüm cihazları gör (id'leriyle)
flutter devices

# Belirli cihaza deploy
flutter run --device-id <DEVICE_ID> --dart-define=API_BASE_URL=<URL>

# iOS simulator
flutter run -d "iPhone 16" --dart-define=API_BASE_URL=http://localhost:5080

# Android emulator (host: 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

## Yasak

- **`--release` modu varsayılan kabul etme** — kullanıcı açıkça istemedi mi debug çalıştır
- **Hardcoded API URL'i içeride bırakma** — `--dart-define` ile geç, koddan okuma
- **Local backend URL kullanma** (`localhost`, `127.0.0.1`) iPhone'da — fiziksel cihaz host makineye `localhost` ile ulaşamaz; ngrok zorunlu
- **Cihaz onayını atlamak için `--device-id` argümanını silmek** — başka cihaza yanlışlıkla deploy riski
