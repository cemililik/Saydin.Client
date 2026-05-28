---
name: yasak-check
description: Audit the current git diff (staged + unstaged) for CLAUDE.md "Yasak Listesi" violations — print() outside debugPrint, HTTP in BLoC/widget, hardcoded Turkish strings, hardcoded colors/URLs, setState in BLoC pages, double for money, Flutter imports in domain layer, HTTP client in BLoC. Reports findings with file plus line and suggests fixes. Use before commit, or when user says "yasak kontrol", "kuralları denetle", "claudemd uyum", "lint custom".
---

`git diff` üzerindeki değişiklikleri CLAUDE.md'deki **Yasak Listesi** kurallarına karşı denetler. Commit öncesi güvenlik ağı.

> Bu skill bir audit aracı — kod yazmaz, raporlar. Tespit edilen ihlalleri fix önerisiyle sunar; uygulama kararı kullanıcının.

## İş akışı

1. **Diff topla:**
   ```bash
   git diff HEAD -- '*.dart'    # staged + unstaged Dart değişiklikleri
   ```
   Boşsa: `git diff main...HEAD -- '*.dart'` ile branch'in tüm farkını al.

2. **Her dosyayı kuralla geç** (aşağıdaki kontrol matrisi).

3. **Raporla:** `dosya:satır — ihlal — önerilen düzeltme` formatında, tek tek.

## Kontrol matrisi

### 1. `print()` kullanımı (yasak — `debugPrint()` kullan)
```bash
git diff -- '*.dart' | grep -E '^\+.*\bprint\s*\(' | grep -v 'debugPrint'
```
İhlal varsa: `print(x)` → `debugPrint(x.toString())` (debugPrint sadece String alır).

### 2. Hardcoded Türkçe string
**Heuristik**: Dart string literal'i içinde [ığüşöçĞÜŞÖÇİ] karakterleri varsa şüpheli.
```bash
git diff -- '*.dart' | grep -E "^\+.*['\"][^'\"]*[ığüşöçĞÜŞÖÇİ][^'\"]*['\"]" | grep -v 'app_localizations\|app_tr\|app_en'
```
İhlal varsa: `context.l10n.<key>` çevirisi ekle ([l10n-add](../l10n-add/SKILL.md)).

### 3. Hardcoded renk (widget içinde `Color(0xFF...)` veya `Colors.X.shade...`)
```bash
git diff -- '*.dart' | grep -E '^\+.*\b(Color\(0x|Colors\.[a-zA-Z]+\.shade)' | grep -v 'core/constants\|core/theme'
```
İhlal varsa: `lib/core/constants/app_colors.dart` veya `lib/core/theme/...` altına taşı, oradan import et.

### 4. Hardcoded API URL
```bash
git diff -- '*.dart' | grep -E "^\+.*['\"](https?://|/v[0-9]+/)" | grep -v 'core/network/api_endpoints\|dart-define'
```
İhlal varsa: `lib/core/network/api_endpoints.dart`'a sabit ekle; URL `--dart-define=API_BASE_URL` ile geçilir.

### 5. `setState` BLoC sayfasında
**Tespit**: Aynı dosyada `BlocProvider` veya `BlocBuilder` import varsa, `setState(` kullanımı yasak.
```bash
# Hangi dosyalar değişti?
git diff --name-only HEAD -- '*.dart' | while read f; do
  if grep -q 'BlocProvider\|BlocBuilder\|BlocConsumer' "$f" 2>/dev/null && \
     grep -q 'setState(' "$f" 2>/dev/null; then
    echo "$f — BLoC + setState bir arada"
  fi
done
```
İhlal varsa: `setState` çağrısı yerine state'i BLoC'a taşı, `context.read<XBloc>().add(...)` ile event gönder.

### 6. `double` para tutarı için
**Sinyal**: `amount`, `price`, `try`, `total`, `value` gibi para semantiği olan alanlar `double` tip.
```bash
git diff -- '*.dart' | grep -E '^\+.*\bdouble\b.*(amount|price|total|try|tl|tr[yY]|value|cost|fee)'
```
İhlal varsa: `num` (Dart) veya server'dan gelen `String` → controlled parse. Display için `NumberFormat.currency(locale: 'tr_TR', symbol: '₺')`.

### 7. Domain'de Flutter import
**Tek `*` dizin sınırını aşmaz** — domain dosyaları `domain/{entities,repositories,usecases}/` altındadır. Recursive globbing için `**` veya `git ls-files` kullan:
```bash
git diff -- 'lib/features/*/domain/**/*.dart' | grep -E "^\+.*import 'package:flutter/"

# Alternatif (daha güvenli, recursive):
git diff --name-only HEAD -- '*.dart' | grep '/domain/' | while read f; do
  grep -l "^import 'package:flutter/" "$f" 2>/dev/null
done
```
İhlal varsa: domain'den çıkar; UI semantikleri (renk, ikon, asset) `presentation/` katmanına taşı.

### 8. BLoC içinde HTTP client
**Tespit**: BLoC sınıfında `Dio`, `http.Client`, veya `ApiClient` türünde field.
```bash
git diff -- '**/presentation/bloc/*.dart' | grep -E "^\+.*\b(Dio|http\.Client|ApiClient)\b"
```
İhlal varsa: HTTP çağrısı Use Case katmanına alınmalı; BLoC sadece Use Case'i çağırır.

### 9. Widget içinde HTTP çağrısı
```bash
git diff -- 'lib/features/*/presentation/pages/**/*.dart' 'lib/features/*/presentation/widgets/**/*.dart' | \
  grep -E '^\+.*\b(\.get\(|\.post\(|http\.get|dio\.)'
```
İhlal varsa: Use Case + BLoC üzerinden geç.

### 10. `Equatable` props'ta function field
**Tespit**: `Equatable` mixin'i kullanan sınıfta `Function`, `VoidCallback`, callback tipinde field.
```bash
git diff -- '*.dart' | grep -B 5 'extends Equatable\|with Equatable' | grep -E 'final (Function|VoidCallback|Callback|.*Function\b)'
```
İhlal varsa: callback'ler state'in dışında, parent widget'tan parametre olarak geçilir.

## Rapor formatı

```
🔍 Yasak Listesi Denetimi — N ihlal bulundu

❌ lib/features/portfolio/presentation/pages/portfolio_page.dart:42
   İhlal: print() kullanımı
   Düzeltme: debugPrint('Portföy yüklendi: ${data.length} kayıt')

❌ lib/features/portfolio/presentation/widgets/asset_card.dart:18
   İhlal: Hardcoded Türkçe metin "Portföyüm"
   Düzeltme: context.l10n.myPortfolio ekle (app_tr.arb + app_en.arb)

❌ lib/features/portfolio/domain/entities/portfolio_asset.dart:5
   İhlal: import 'package:flutter/material.dart' domain'de yasak
   Düzeltme: Domain'den çıkar; Icons.foo kullanımını presentation'a taşı

✅ Diğer kurallar temiz (BLoC + HTTP, double + money, ...)
```

İhlal yoksa: `✅ Tüm Yasak Listesi kontrolleri temiz — commit'e hazır`.

## Sınırlar (false-positive riski)

Bu heuristik'ler kesin değil. Manuel doğrulama gerekenler:
- **Türkçe karakter heuristiği** doc string'leri (`/// Türkçe açıklama`) yakalayabilir — comment'leri filtrele.
- **Color(0xFF...)** test dosyalarında veya theme tanımında geçerli — `core/theme/`, `test/` dizinlerini hariç tut.
- **`double` field'lar** matematiksel istatistik veya yüzde için olabilir (örn. `coverageRatio`). Sadece para alanlarında yasak.

Şüpheli durumda kullanıcıya sun, otomatik fix uygulama.

## Bitiş

- [ ] Tüm değişen dosyalar tarandı
- [ ] Her ihlal `dosya:satır` ile raporlandı
- [ ] Önerilen fix net (kopyalanabilir)
- [ ] False-positive şüphesi varsa işaretlendi
- [ ] İhlal yoksa "temiz" raporu verildi

## İlişkili skill'ler

- [feature-scaffold](../feature-scaffold/SKILL.md) — yeni feature yazarken yasak'lardan kaçınmak için
- [l10n-add](../l10n-add/SKILL.md) — hardcoded Türkçe ihlalini düzeltirken
