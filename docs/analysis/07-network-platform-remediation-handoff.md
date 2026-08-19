# Ağ ve platform güvenliği remediation handoff'u

**Tarih:** 2026-08-18
**Çalışma branch'i:** `development`
**Kapsam:** `SEC-08`, `SEC-11`, `SEC-17`, `SEC-19`, `SEC-22`

| Finding | Durum | Uygulanan teknik karar | Doğrulama | Kalan bağımlılık/risk |
|---|---|---|---|---|
| SEC-08 | `VERIFICATION` | API URL bootstrap'ta eager doğrulanır; origin-only authority, release/profile HTTPS host ve port kuralları validator'da fail-closed'dur. | URL matrisi + DI başlangıç testi | Gerçek production/staging origin sahipliği `SEC-02` kapsamında dış karardır; bu değişiklik onu çözmez. |
| SEC-11 | `AWAITING_EXTERNAL` | Var olmayan `/v1/account/data-export` iddiası teknik dokümandan kaldırıldı. İstemci endpoint/repository/UI uydurmaz; mevcut legal başvuru kanalına yönlendirir. | `CLAUDE.md` teknik sözleşme güncellemesi | Backend authenticated export sözleşmesi, status ve güvenli teslim tasarımı yoktur. Hukuk/operasyon onayı gerekir. |
| SEC-17 | `VERIFICATION` | Debug `Info-Debug.plist` yalnız localhost ATS exception taşır; Release/Profile `Info.plist` local networking/HTTP exception içermez. | plist lint + platform config testi | Signed IPA effective-plist/device smoke `SEC-18` kapsamındadır ve kullanıcı tarafından ertelenmiştir. |
| SEC-19 | `VERIFICATION` | GET/HEAD retry, `sendTimeout`, sunucu `Retry-After` (en çok 30 sn), iptal edilebilir bekleme ve enjekte edilebilir clock/backoff ile tamamlandı. Cancel bir `ServerError` değildir. | Deterministik retry/cancel/header testleri | Retry yalnız idempotent GET/HEAD'dir; POST/DELETE otomatik tekrar edilmez. |
| SEC-22 | `VERIFICATION` | Dart ve Android debug HTTP allowlist'i: `localhost`, `127.0.0.1`, `10.0.2.2`. Tünel/LAN HTTP yasak, HTTPS zorunlu; README runbook'u aynı sözleşmeyi açıklar. | Kaynak-konfigürasyon-runbook sözleşme testi | Fiziksel cihaz için makineye erişim TLS'li LAN origin'i veya HTTPS tünel gerektirir. |

## Operasyonel notlar

1. `Retry-After` yalnız already-retryable 502/503/504 cevaplarında uygulanır.
   `429` günlük limit/iş kuralı olarak ayrı hata semantiğinde kalır; istemci
   kullanıcı aksiyonu olmadan onu yeniden denemez.
2. `sendTimeout` artık 15 saniye olarak explicit ayarlanır ve idempotent
   isteklerde diğer timeout türleriyle aynı retry politikasına girer.
3. Release/profile platform konfigürasyonu local HTTP'yi desteklemez. Bu,
   Dart doğrulamasını atlayan native SDK çağrıları için de savunma katmanıdır.
