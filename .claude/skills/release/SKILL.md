---
name: release
description: Create an annotated git tag with TR/EN release notes (separator format) and push it to trigger the tag-driven release workflow. RC tags (v0.2.0-rc.1) deploy to staging, plain tags (v0.2.0) require GitHub Environment approval for production %10 staged rollout. Use when user says "release çıkar", "tag at", "yeni sürüm", "release oluştur", or "tag yarat".
---

Tag-driven release sürecini başlatır. `.github/workflows/release.yml` sadece `v*` formatında annotated tag push'ları dinler — bu skill o tag'i CLAUDE.md'ye uygun şekilde oluşturup gönderir.

> Pre-flight: `main` güncel ve [CI](https://github.com/cemililik/Saydin.Client/actions) yeşil olmalı. Aksi halde release iptal et — guard job zaten engelleyecek ama vakit kaybı.

## Önce sor (sırayla)

1. **Kanal**: production (`v0.2.0`) mı, staging RC (`v0.2.0-rc.1`) mı?
   - Hangisini önerirsin: Eğer kullanıcı yeni özelliği QA'dan geçirmemişse RC; geçirmişse production.
2. **Versiyon numarası**: Son tag ne? (`git tag -l 'v*' --sort=-v:refname | head -3`) Önerilen bump:
   - `feat:` commitler varsa → MINOR (`0.1.0` → `0.2.0`)
   - Sadece `fix:` / `perf:` → PATCH (`0.1.0` → `0.1.1`)
   - `feat!:` veya `BREAKING CHANGE:` → MAJOR (`0.1.0` → `1.0.0`)
3. **Türkçe release notes**: ≤500 karakter, kullanıcı dostu — teknik terim yok. Emoji önerilir:
   - Yeni özellik: ✨
   - Hata düzeltme: 🐛
   - İyileştirme: ⚡
4. **İngilizce release notes**: TR'ın çevirisi, aynı format

## Tag formatı (KESINLIKLE bu format)

```
<tag-adı>

<Türkçe satır 1>
<Türkçe satır 2>
...

=====LANG_SEPARATOR=====

<English line 1>
<English line 2>
...
```

İlk satır tag adı (örn. `v0.2.0`) — GitHub Release başlığı olur. Sonra boş satır, sonra Türkçe gövde, sonra ayraç, sonra İngilizce gövde.

## İş akışı

1. **Son commit'in main'de olduğunu doğrula:**
   ```bash
   git fetch origin main
   git merge-base --is-ancestor HEAD origin/main && echo "✅ main'de" || echo "❌ main'de değil"
   ```
   Değilse: önce PR merge et, sonra release. Guard job aksini engeller.

2. **Versiyon planla:**
   ```bash
   git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -5
   git log $(git tag -l 'v*' --sort=-v:refname | head -1)..HEAD --oneline
   ```
   Önerilen versiyonu kullanıcıya sun.

3. **Annotated tag oluştur** (heredoc ile çok satırlı mesaj):
   ```bash
   git tag -a v0.2.0 -m "v0.2.0

   ✨ Portföy ekranı eklendi.
   🐛 Grafik render hatası düzeltildi.
   ⚡ Liste scroll performansı iyileştirildi.

   =====LANG_SEPARATOR=====

   ✨ New portfolio screen.
   🐛 Fixed chart rendering bug.
   ⚡ Improved list scroll performance.
   "
   ```

4. **Tag'i lokal doğrula:**
   ```bash
   git tag -l --format='%(contents)' v0.2.0
   ```
   Format doğru görünüyor mu? Ayraç var mı?

5. **Kullanıcıdan onay al** push öncesi. Push'ladıktan sonra geri dönüş zor (Play Console'da çift sürüm olur).

6. **Push:**
   ```bash
   git push origin v0.2.0
   ```

7. **Workflow'u izle:**
   ```bash
   gh run watch $(gh run list --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId')
   ```
   Veya: https://github.com/cemililik/Saydin.Client/actions

8. **Production tag ise:** GitHub Environment `production` onayı gerekecek — onay verecek kişiye haber et.

9. **Staged rollout (production):** Workflow başarılı tamamlandıktan sonra Play Console → Production → Manage release ekranından 24-48h sonra crash-free rate kontrol edip %25 → %50 → %100 elle promote et.

## Hatalı senaryolar

**Lightweight tag attım, ne yaparım?**
- Çek geri: `git tag -d v0.2.0 && git push origin :refs/tags/v0.2.0`
- Annotated olarak yeniden at (yukarıdaki adımlar)
- NOT: Eğer remote tag tetiklenmişse ve store upload başladıysa hareket etme — Play Console'da çift sürüm çıkar; bir sonraki versiyona geç (`v0.2.1`).

**Yanlış versiyon attım (e.g. v0.3.0 yerine v0.20.0):**
- Tag push'lanmadıysa: yukarıdaki gibi sil ve yeniden at
- Push'landıysa ve workflow başladıysa: workflow'un GitHub Environment onay aşamasında "Reject"  → sonra `v0.3.0` olarak yeniden at

**RC ile başladım, prod'a geçmek istiyorum:**
- Aynı versiyonu non-RC olarak yeniden at: `v0.2.0-rc.1` → `v0.2.0`
- Build number `github.run_number`'dan geleceği için çakışma olmaz

## Bitirmeden önce kontroller

- [ ] `main` güncel ve CI yeşil
- [ ] Tag formatı: subject + boş satır + TR + boş + separator + boş + EN
- [ ] TR ve EN ≤500 karakter (Play Store limiti)
- [ ] Versiyon SemVer doğru bump'lanmış
- [ ] Annotated (`-a` veya `-m` flag), lightweight DEĞİL
- [ ] Push öncesi kullanıcı onayı alındı
- [ ] Production ise Environment onayı verecek kişi haberdar

## Yasak

- **Lightweight tag** (`git tag v0.2.0`) — annotated message yok, fallback son commit subject'i, release notes anlamsız
- **Tag'i `main`'de olmayan commit'e koymak** — guard job hata verir
- **Aynı versiyonu yeniden push** — Play Console çift sürüm görür; semver bump et
- **`git push --tags`** — TÜM tag'leri push'lar, sadece istediğin tag'i push'la: `git push origin v0.2.0`
- **`=====LANG_SEPARATOR=====` ayracını unutmak** — TR ve EN aynı metni alır
