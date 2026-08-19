# Legal Release Sign-off Review Remediation

**Tarih:** 2026-08-18
**Branch:** `development`
**İncelenen ana kaynak:** `docs/legal/legal-release-signoff.md` için kullanıcı
tarafından sağlanan kritik/yüksek/orta/düşük review
**Sonuç:** Depo içinde güvenle çözülebilen bulgular uygulandı; gerçek hukuk ve
altyapı otoritesi gerektiren maddeler fail-closed dış blokaj olarak bırakıldı.

## Sonuç özeti

- Approval sözleşmesi schema v2'ye yükseltildi.
- Dört legal metin hash'ine ek olarak tüm production Dart kodu, TR/EN ARB'ler,
  platform privacy bildirimleri, backup XML'leri ve dependency lock'u kapsayan
  `runtime_surface_sha256` eklendi.
- Production sırası, legal metin → bundle hash/runtime sabiti → runtime hash →
  insan onayı → source commit → JSON-only approval commit → exact-SHA CI →
  immutable annotated tag olarak düzeltildi.
- Approver girdileri gerçekliği kanıtlanmış sayılmıyor. Buna rağmen kısa/aynı
  ad, aynı identity, biçimsiz identity/evidence, gelecekteki ve 30 günden eski
  zamanlar artık reddediliyor.
- Resmî veri sorumlusu unvanı, tebligat adresi ve resmî başvuru kanalının JSON'da
  bulunması ve dört legal kaynağın her birinde birebir yer alması zorunlu oldu.
- Sentry auto-session ve session replay runtime'da açıkça kapatıldı; pre-notice
  başlangıç telemetrisi ve native-envelope sınırı dokümante edildi.

## Bulgu matrisi

| Review konusu | Sonuç | Uygulama |
|---|---|---|
| Üretim sırası/hash-version çelişkisi | DONE | Sign-off, release skill, CLAUDE ve development guide aynı uygulanabilir sıraya taşındı |
| Tek karakter/sahte approver | PARTIAL / EXTERNAL | Ad/identity/evidence/benzersizlik/freshness sertleştirildi; gerçek yetki kriptografik olarak kanıtlanmış sayılmıyor |
| Sign-off'un makinece parse edildiğinin gizli kalması | DONE | Makine ve insan sorumlulukları ile literal gate kuralları §0'da açıklandı |
| Yalnız iki title marker'ı taranması | DONE | Gövde dahil TR/EN taslak ve yayın-engeli regex'leri, testler ve pozitif controller disclosure şartı eklendi |
| Store release Sentry DSN gerçeği | DONE | Envanter ve dört kullanıcı metni release workflow gerçeğiyle hizalandı |
| Native session envelope açığı | DONE | `enableAutoSessionTracking=false`; session replay iki sample rate ile explicit `0.0` |
| Pre-notice Sentry aktarımı | DONE | Saydın API gate'inden ayrı Sentry kapsamı envantere işlendi |
| Yalnız legal metinleri bağlayan hash | DONE | `runtime_surface_sha256` ve CLI komutu eklendi |
| ARB/Info.plist privacy string'leri hash dışında | DONE | Runtime/privacy hash ARB, Info plist/string ve manifestleri kapsıyor |
| Dört legal dosyanın adlandırılmaması | DONE | `LEGAL_FILES` ve dört yol belgede açık listelendi |
| Belgenin release dokümanlarından keşfedilememesi | DONE | CLAUDE, development guide ve release skill linkleri eklendi |
| `BLOCKED — açıklama` exact-status tuzağı | DONE | Durum yalnız `BLOCKED`; açıklama ayrı metadata satırı |
| JSON alanları/zaman/version semantiği eksik | DONE | Schema v2 alanları, UTC, 30 gün freshness, latest timestamp ve controller nesnesi belgelendi |
| Paylaşım motoru/giriş noktası/tetikleyici hatası | DONE | Ortak sheet/renderer, dört feature ve yalnız Share eyleminde disk yazımı belirtildi |
| Share dosyası saklama katmanları | DONE | `finally`, startup 1 saat/20 dosya ve account wipe yazıldı |
| Fotoğraflar add-only akışı | DONE | Ayrı envanter satırı, InfoPlist kanıtları ve olası kullanıcı iCloud sync sınırı eklendi |
| iOS backup belirsizliği | DONE / EXTERNAL VERIFY | Android kapalı/Keychain this-device gerçekleri ve iOS prefs/Application Support belirsizliği ayrıldı; cihaz kararı checklist'e eklendi |
| §2 kanıtsız checkbox'lar | DONE | Checked satırda inline URL/URN kanıt zorunlu; tabloya kanıt kolonu eklendi |
| Approval yaşam döngüsü | DONE | Her production tag için yeniden review, değişiklik tetikleyicileri ve 30 gün freshness tanımlandı |
| Processor adlarının metinlere taşınmaması | PROCESS BLOCKER | TR/EN'e tüzel ad/ülke/amaç aktarımı zorunlu checklist maddesi |
| VERBİS/envanter/imha politikası | PROCESS BLOCKER | Ayrı zorunlu checklist maddeleri |
| Yanlış KVKK başvuru kaynağı | DONE | 2018 Başvuru Usul ve Esasları Tebliği kullanıldı |
| Apple forumun birincil kaynak sayılması | DONE | İkincil/operasyonel nota taşındı |
| Partial account wipe/marker | DONE | Durable marker, partial retry ve backend'i tekrarlamama semantiği açıklandı |
| Ephemeral UUID/Keychain sınıfı | DONE | Envanterde süreç-ömürlü fallback ve exact iOS seçenekleri yazıldı |
| Portfolio endpoint/senaryo plan/Android OS | DONE | Per-item what-if, GET `plan`, Android `unknown` ayrıntıları eklendi |
| Sentry replay/attachment doğrulanmış client kontrolleri | DONE | Replay explicit kapalı; Dart attachment scrubber kontrolü doğrulanan alana taşındı |
| RC taslak riski | DONE / OWNER CONTROL | Internal/TestFlight kapsamı ve sınırlı yetkili tester şartı yazıldı |
| N/A konvansiyonu | DONE | Gerekçe + owner + kanıt biçimi tanımlandı |
| Tablo içi render olmayan `[ ]` | DONE | §3 düz `BEKLEMEDE/ONAYLANDI` durumuna geçti |
| Mermaid/revizyon/kapsam dışı | DONE | Akış diyagramı, revizyon ve açık dış kapsam bölümü eklendi |
| GDPR/AB ve Play deletion declaration | PROCESS BLOCKER | Yayın coğrafyası/store checklist'ine eklendi |
| Global `PENDING` prose collision | DONE | Placeholder taraması approval bölümüne; açık checkbox regex'i task-list satırına daraltıldı |

## Dış blokajlar

1. Veri sorumlusunun resmî unvanı/adresi/başvuru kanalı ve processor gerçekleri
   repository'den çıkarılamaz; legal kaynaklar bilinçli biçimde taslak kalır.
2. Gerçek bağımsız GitHub approver, environment protection, self-review yasağı,
   CODEOWNERS ayrımı veya GPG/SSH public-key allowlist'i dış kimlik kararı
   gerektirir. Agent sahte owner/kimlik eklememiştir.
3. `docs/legal/`, verifier ve workflow değişiklikleri `development` üzerinde
   version control'e alınmıştır; production gate'in remote `main` tarihinde
   etkin olması için normal PR/merge ve exact-SHA CI süreci hâlâ gereklidir.
4. Backend deletion/export/log/backup, production Sentry console, iOS gerçek
   cihaz backup/uninstall ve store beyanları dış sistem kanıtı bekler.
5. Hukuk/DPO nihai metni onaylayıp taslak ifadelerini kaldırmadan production
   verifier'ın başarısız olması beklenen ve doğru davranıştır.

## Doğrulama

- Legal verifier unit testleri: 18/18 geçti.
- Non-Dart quality testleri: 25/25 geçti.
- Repository contract/link doğrulaması: geçti; 405 yerel Markdown linki.
- ARB sözleşmesi: TR/EN 256 mesaj eşliği geçti.
- Coverage manifest: 159 production library için güncel.
- `flutter analyze --fatal-infos`: temiz.
- Tam Flutter suite: 537/537 geçti.
- Dart format ve `git diff --check`: temiz.
- Güncel legal bundle hash:
  `b91df0f5275fc0c457a035fbfab8a0c374c81aca02724f9a5bb109dc8da0fa0b`.
- Güncel runtime/privacy surface hash:
  `a043b1327641447763b4a1c4ba88e46429a43c4342664b70688216ac77a5951d`.
