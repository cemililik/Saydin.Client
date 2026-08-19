---
name: develop-task
description: End-to-end develop the next task with care and minimal rework. Read the surrounding code first, understand context fully, then decide the order yourself. Follow CLAUDE.md, project standards, and clean code principles. After implementing, verify compatibility, run lint+test, update docs (roadmap/guide/readme/changelog), commit with conventional message, produce a detailed Turkish summary, and finally write a task-specific review-agent prompt. Use when user says "sıradaki işi geliştir", "task'i tamamla", "implement task", "geliştirmeyi yap", or has just queued a development task.
---

Bir geliştirme görevini **baştan sona, az hata, az fix turuyla** tamamlamak için disiplinli akış.

> Bu skill yavaş işler — acele etmemek tasarımın parçası. "Çabuk yaptım sonra fix'lerim" tercih edilmez; ilk seferde doğru yapmak hedeftir.

## Faz 0 — Anla (kod yazmadan önce)

1. **Görevi tanımla** — kullanıcı ne istedi? Belirsizlik varsa **soru sor** (`grill-me` skill'inin tarzıyla).
2. **Mevcut yapıyı oku:**
   - Hangi feature'ı etkiliyor? `lib/features/<x>/` tamamen
   - İlgili core katman: `lib/core/{network|di|error|theme|...}/`
   - Mevcut benzer pattern'ler — başka feature nasıl yapmış?
3. **Proje kuralları:** [CLAUDE.md](../../../CLAUDE.md) yasak listesi, [docs/architecture.md](../../../docs/architecture.md) katman bağımlılığı ve kanonik [financial/error contract](../../../docs/engineering/financial-error-contract.md).
4. **Bağımlılıkları haritalandır:** Use case yeni mi? DI kaydı gerekiyor mu? Yeni l10n key'i? Yeni endpoint?
5. **Bittiğinde ne görünmesi gerek?** — bitiş kriterlerini söz haline getir.

Bu fazı **atlamadan** bir sonraki faza geçme. Anlamadığın bir nokta varsa kullanıcıya sor.

## Faz 1 — Plan

1. **Sıralamayı kendin belirle** — bağımlılığa göre topolojik:
   - Önce domain entity + repository interface
   - Sonra data model + repository impl
   - Sonra use case
   - Sonra BLoC + Event/State
   - Sonra page + widget'lar
   - DI kaydı her yeni sınıfla beraber
   - L10n key'leri kullanıldığı an
   - Test'ler implementation ile paralel (TDD'ye yakın)
2. Runtime'da bir plan/progress aracı varsa adımları onunla kaydet; yoksa
   aynı durumları kısa bir Markdown checklist ile takip et. Belirli bir araç
   adının varlığını varsayma.
3. **Bir oturumda her şeyi yapma yaklaşımı** — küçük doğrulanabilir adımlar:
   - Bir dosya yaz / değiştir → `flutter analyze` (o dosyaya odaklı) → ilerle
   - 4-5 dosya birikince `flutter test` ilgili test dosyalarıyla
4. **Var olan skill'leri kullan**:
   - Yeni feature ise [feature-scaffold](../feature-scaffold/SKILL.md)
   - Yeni sayfa için [bloc-page](../bloc-page/SKILL.md)
   - L10n key'i için [l10n-add](../l10n-add/SKILL.md)

## Faz 2 — Uygula

1. **Küçük commit-able adımlar** — her adım analyzer'dan temiz geçmeli (commit etme henüz, ama her adım potansiyel commit noktası).
2. **Sıklıkla "neden böyle yapıyorum?" sor** — alternatifi var mı, daha temiz olabilir mi?
3. **Yasak listesi otomatik refleks**:
   - String → `context.l10n.<key>` mi?
   - Renk → `AppColors.*` mi?
   - Para → `Decimal`; JSON sınırında `MoneyParser` kullanılıyor mu?
   - HTTP → BLoC'ta yok, use case üzerinden mi?
4. **Comment yazma alışkanlığı** — CLAUDE.md "WHY non-obvious" kuralı. WHAT yazılmaz.
5. **Mesajlar gerçeği yansıtsın** — `// TODO: ileride x yap` yazıyorsan ya yap ya yazma.

## Faz 3 — Uyum Kontrolü (kod yazıldıktan sonra, commit'ten önce)

1. **Mevcut yapı ile uyum:**
   ```bash
   # DI'da yeni sınıflar kayıtlı mı?
   grep -n "register" lib/core/di/injection.dart | tail -20

   # L10n key'leri TR+EN senkron mu?
   diff <(jq -r 'keys[]' lib/l10n/app_tr.arb | grep -v '^@' | sort) \
        <(jq -r 'keys[]' lib/l10n/app_en.arb | grep -v '^@' | sort)
   ```
2. **[yasak-check](../yasak-check/SKILL.md) skill'i çalıştır** — diff'i CLAUDE.md yasak listesine karşı tara.
3. **Beklenmedik dokunulan dosya var mı?** `git status` — değişiklik kapsamın dışında bir şey varsa açıklaması olmalı.
4. **Yeni public API mı eklendi?** — varsa doc string ekle (`/// ...`).

## Faz 4 — Linter + Test

```bash
# Format
dart format lib/ test/

# Linter (CI ile aynı kural)
flutter analyze --fatal-infos

# L10n üretimi (arb değiştiyse)
flutter gen-l10n

# Test (etkilenen feature + core)
flutter test test/features/<feature>/ test/core/ --coverage

# Coverage (önce-sonra karşılaştır)
```

Hata varsa **commit'lemeden** düzelt. "Sonra fix'lerim" YASAK.

## Faz 5 — Dokümantasyon

Değişiklik aşağıdakilerden birini etkiliyorsa **aynı PR'da** güncelle:

| Dosya | Tetik |
|---|---|
| [docs/architecture.md](../../../docs/architecture.md) | Yeni katman, pattern, paket |
| [docs/development-guide.md](../../../docs/development-guide.md) | Yeni komut, env değişkeni, sorun |
| `docs/decisions/ADR-XXX-<konu>.md` | Büyük mimari karar |
| [README.md](../../../README.md) | Onboarding adımı, screenshot, demo |
| [CLAUDE.md](../../../CLAUDE.md) | Proje kuralı eklendi/değişti (nadir) |
| `pubspec.yaml` | Yeni dependency |

Doc update **kod commit'i ile birlikte** yapılır, ayrı commit değil.

## Faz 6 — Commit

1. **Conventional Commits** ([CLAUDE.md](../../../CLAUDE.md) bölümü):
   - `feat(scope): kısa açıklama` — yeni özellik
   - `fix(scope): kısa açıklama` — bug
   - `refactor(scope): ...` — davranış değişmiyor
   - `docs: ...` — sadece doc değişti
2. **Body'de WHY** — değişikliğin nedeni 1-3 paragraf.
3. **Hooks ATLAMA** — pre-commit hook (format + analyze) hata verirse: hatayı düzelt, sonra commit. `--no-verify` YASAK.
4. **Co-Authored-By** Claude için zaten harness ekliyor (otomatik).

## Faz 7 — Detaylı Özet (kullanıcıya teslim)

Bu skill'in en önemli son adımı. Aşağıdaki yapıda Türkçe özet üret:

```markdown
## Yapılan İş — <Başlık>

### Ne yapıldı (kapsam)
- ...
- ...

### Hangi dosyalar değişti
| Dosya | Tür | Etki |
|---|---|---|
| `lib/features/x/data/...` | yeni | ... |
| `lib/features/x/presentation/bloc/x_bloc.dart` | düzenlendi | ... |
| `lib/l10n/app_tr.arb` | düzenlendi | 3 yeni key |
| ... | ... | ... |

### Mimari etkiler
- DI değişikliği: ...
- Yeni katman/pattern: ...
- API contract: ...

### Bu fazda yapılanların kullanıcıya ne anlam ifade ettiği
(Teknik olmayan dilde, kullanıcı hikayesinde:)
Bu değişiklikten sonra kullanıcı X yapabilir hale gelir.
Y senaryosunda Z davranış değişti.
...

### Test sonuçları
- Analyzer: ✅ 0 hata
- Test: ✅ N test geçti, M skipped
- Coverage: önceki %X → güncel %Y

### Doküman güncellemeleri
- `docs/architecture.md`: ... (eklendi/düzenlendi)
- `README.md`: ...
- ADR: ...

### Açık sorular / sonraki adım
- (Varsa)
```

## Faz 8 — Task'a Özel Review Agent Promptu

**Son adım** — bu task'in sonra detaylı review edilebilmesi için kullanıcıya bir agent promptu yaz. Bu, master-review skill'inden farklı:

- Master-review = tüm proje
- Bu = sadece bu PR'ın değişiklikleri

Şablon:

```
Sen Saydın projesinin <feature/scope> kapsamında yapılan değişikliklerin
review ajanısın.

KAPSAM: Aşağıdaki commit/diff'i incele:
- Commit: <hash veya branch>
- Etkilenen dosyalar:
  - <liste>

GÖREV:
1. Her dosyayı baştan sona, bağlamıyla beraber oku.
2. Şu lens'lerden bak:
   - correctness: değişiklik mantıklı mı, edge case'leri kapsıyor mu?
   - security: <task-spesifik güvenlik soruları>
   - performance: <task-spesifik performans>
   - refactor: alternatif daha temiz mi?
   - business_logic: <task-spesifik iş kuralı>
   - documentation: doc güncel mi, eksik mi?
   - testability: test edilebilirlik?
   - claudemd_compliance: yasak listesi ihlali?
3. Saydın'a özgü kurallar için CLAUDE.md ve docs/architecture.md referans.

BAĞLAM:
<bu task'in iş hikayesini 2-3 paragraf yaz — agent'ın "ne yapmaya
çalışıyordu?" sorusunu yanıtlayabilmesi için>

ÇIKTI: Markdown rapor:
- Yönetici özeti (3-5 cümle)
- Bulgular (severity: 🔴/🟠/🟡/🟢)
  - Konum (file:line)
  - Kategori
  - Açıklama
  - Etki
  - Öneri
- "İyi yapılan" gözlemler
- Açık sorular

KURALLAR:
- Acele etme.
- "Olur" deme — gerekçeli ol.
- Kod değişikliği YAPMA, sadece raporla.
```

Bu prompt kullanıcıya **mesaj olarak** sunulur — kopyalayıp yeni session'a yapıştırabileceği şekilde.

## Bitirmeden önce

- [ ] Faz 0-7 tamamlandı
- [ ] Analyzer + test temiz
- [ ] Doküman güncel
- [ ] Conventional commit atıldı
- [ ] Detaylı Türkçe özet kullanıcıya sunuldu
- [ ] Task'a özel review prompt'u yazıldı

## Yasak

- **"Sonra fix'lerim"** — şimdi düzelt
- **Faz atlamak** — anlama fazını atlamak en yaygın hata
- **Acele commit** — pre-commit hata verdiyse, hata fix'i ayrı commit değil, aynı commit'i yeniden yarat
- **"Çalıştı, tamam"** — testler de geçmeli, sadece manuel doğrulama yeterli değil
- **Doc atlamak** — kod davranışı değişti ama doc eski → teknik borç
- **Özet atlamak** — kullanıcıya teslim olmadan task bitmiş sayılmaz

## İlişkili Skill'ler

- [grill-me](../grill-me/SKILL.md) — anlama fazında belirsizlik varsa
- [feature-scaffold](../feature-scaffold/SKILL.md) — yeni feature gerekiyorsa
- [bloc-page](../bloc-page/SKILL.md) — yeni sayfa gerekiyorsa
- [l10n-add](../l10n-add/SKILL.md) — yeni string gerekiyorsa
- [yasak-check](../yasak-check/SKILL.md) — Faz 3 uyum kontrolünde
- [device-deploy](../device-deploy/SKILL.md) — UI değişikliği iPhone'da doğrulama
- [release](../release/SKILL.md) — task release-ready ise tag çıkarma
- [master-review](../master-review/SKILL.md) — büyük checkpoint'lerde, ayrı operasyon
