---
name: l10n-add
description: Add a localization key to BOTH lib/l10n/app_tr.arb and lib/l10n/app_en.arb (with placeholder definitions if needed), validate sync, and run flutter gen-l10n. Use when adding any user-facing string, or when user says "l10n ekle", "yeni çeviri", "translation key ekle", "string ekle".
---

`app_tr.arb` ve `app_en.arb` dosyalarına **paralel** key ekler, placeholder'ları doğrular, `flutter gen-l10n` çalıştırır.

> Tek dilli ekleme YASAK — bir dosyada key olmazsa runtime'da fallback davranışı sessizce devreye girer ve test'lerde yakalanmaz.

## Önce sor (eksikse)

1. **Key adı** (camelCase, örn. `inflationCompareTitle`)
2. **Türkçe metin**
3. **İngilizce metin**
4. **Placeholder var mı?** Format: `{amount}` `{percent}` gibi
5. Placeholder varsa her birinin **tipi** (`String`, `int`, `double`, `DateTime`)

## Doğru ARB formatı

**Basit string (placeholder yok):**

```json
// lib/l10n/app_tr.arb
{
  "inflationCompareTitle": "Enflasyon Karşılaştırması"
}

// lib/l10n/app_en.arb
{
  "inflationCompareTitle": "Inflation Comparison"
}
```

**Placeholder'lı string:**

```json
// lib/l10n/app_tr.arb
{
  "profitMessage": "{amount} kazanç ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": { "type": "String" },
      "percent": { "type": "String" }
    }
  }
}

// lib/l10n/app_en.arb
{
  "profitMessage": "{amount} profit ({percent})",
  "@profitMessage": {
    "placeholders": {
      "amount": { "type": "String" },
      "percent": { "type": "String" }
    }
  }
}
```

**Önemli:** `@<key>` meta nesnesi (placeholders) **HER İKİ** arb dosyasında da bulunmalı, aksi halde `flutter gen-l10n` üretimde "placeholder type unknown" hatası verir.

## İş akışı

1. Key'i her iki dosyaya da ekle. Alfabetik sıralama gerek yok — mevcut sıraya devam et (genelde feature'a göre gruplama var).
2. **Placeholder varsa** her iki dosyaya da `@key` meta objesini ekle.
3. `flutter gen-l10n` çalıştır.
4. `lib/l10n/app_localizations.dart` ve `app_localizations_tr.dart` / `_en.dart` dosyalarında yeni getter'ı doğrula.
5. Kullanım örneği ver: `context.l10n.inflationCompareTitle` veya `context.l10n.profitMessage(amount: '₺47.010', percent: '%23,4')`.

## Senkronizasyon Kontrolü

Her iki dosyanın aynı key'leri içerdiğini doğrula:

```bash
diff <(jq -r 'keys[]' lib/l10n/app_tr.arb | grep -v '^@' | sort) \
     <(jq -r 'keys[]' lib/l10n/app_en.arb | grep -v '^@' | sort)
```

Boş çıktı = senkron. Çıktı varsa eksik tarafı tamamla.

## Özel durumlar

**ICU plural:**
```json
// lib/l10n/app_tr.arb
{
  "scenarioCount": "{count, plural, =0{Senaryo yok} =1{1 senaryo} other{{count} senaryo}}",
  "@scenarioCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

EN tarafı:
```json
{
  "scenarioCount": "{count, plural, =0{No scenarios} =1{1 scenario} other{{count} scenarios}}",
  "@scenarioCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

**Tarih placeholder'ı:** `format: "yMd"` ile ARB içinden formatlanabilir, ama Saydın'da tarih genelde `dd.MM.yyyy` istendiği için tarihi widget'ta `DateFormat('dd.MM.yyyy', 'tr_TR').format(date)` ile string'e çevir, l10n'a `String` olarak geç.

## Bitiş kontrolleri

- [ ] Hem `app_tr.arb` hem `app_en.arb` güncel
- [ ] Placeholder'lar her iki dosyada tanımlı
- [ ] `flutter gen-l10n` hata vermeden tamamlandı
- [ ] Yeni getter'lar `lib/l10n/app_localizations.dart` içinde görünüyor
- [ ] `flutter analyze --fatal-infos` yeşil (eksik kullanım da hata vermez ama mevcut kullanımlar bozulmamalı)
- [ ] Üretilmiş dosyalar (`app_localizations*.dart`) **commit'lenir** — repo bunları tutuyor

## Yasak

- Sadece TR'a key eklemek — EN sessizce key adını gösterir, kullanıcıya İngilizce metin ulaşmaz
- Placeholder type'ı `String` yerine `Object` bırakmak — `flutter gen-l10n` `Object?` getter üretir ve type safety kaybolur
- `@@locale` satırını kaldırmak — generator bunu zorunlu görür
- Mevcut key'in TR metnini değiştirip EN'i unutmak — A/B test sırasında dil tutarsızlığı çıkar
