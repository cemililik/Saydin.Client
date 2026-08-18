---
name: release
description: Create and push an immutable annotated release tag with TR/EN notes. Production releases require an approved source commit followed by a single-purpose legal approval JSON commit; RC releases use the same immutable-tag and exact-SHA rules without the production legal gate. Use when the user says "release çıkar", "tag at", "yeni sürüm", "release oluştur", or "tag yarat".
---

Saydın'ın `.github/workflows/release.yml` tag-driven release akışını
başlatır. Release tag'i bir kez remote'a push'landıktan sonra immutable'dır.

## Önce sor

1. Kanal: production (`vX.Y.Z`) mı, staging RC (`vX.Y.Z-rc.N`) mi?
2. Versiyon: son tag'leri ve commit'leri inceleyip SemVer bump öner:
   - `feat:` → MINOR
   - yalnız `fix:` / `perf:` → PATCH
   - `feat!:` / `BREAKING CHANGE:` → MAJOR
3. Türkçe ve İngilizce kullanıcı-dostu release notes (her dil ≤500
   karakter).
4. Production ise approval artifact'ine yazılacak gerçek sign-off bilgileri.
   Placeholder veya agent tarafından uydurulmuş onay kullanma.

## Ortak pre-flight

```bash
git fetch origin main --tags
git status --short
git tag -l 'v*' --sort=-v:refname | head -5
git log "$(git tag -l 'v*' --sort=-v:refname | head -1)"..HEAD --oneline
git merge-base --is-ancestor HEAD origin/main
```

Working tree temiz, hedef commit `origin/main` üzerinde ve exact commit için CI
yeşil değilse tag oluşturma. Aynı tag remote'da varsa dur; onu yeniden kullanma,
silme veya taşıma.

## Production protocol — sıra zorunlu

### 0. Legal metin, hash ve insan onayını tamamla

Önce [legal release sign-off](../../../docs/legal/legal-release-signoff.md)
belgesindeki production sırasını uygula. Dört legal kaynaktaki bütün taslak
ifadeleri kaldır; bundle hash'i hesaplayıp
`LegalAcceptanceVersion.bundleSha256` ile eşleştir. Önceki production metni
değiştiyse acceptance version/document ID/tarihi artır. Runtime/privacy yüzeyini
de ayrıca snapshot'la:

```bash
python3 tool/verify_legal_release_approval.py --print-bundle-hash
python3 tool/verify_legal_release_approval.py --print-runtime-surface-hash
```

Beş gerçek ve birbirinden bağımsız rolün kanıtlarını tamamla; sign-off üst ve
nihai durumlarını tam `APPROVED` yap. Agent onayı, isim, identity veya evidence
uyduramaz. Approval JSON bu aşamada source commit SHA bilinmediği için henüz
commit edilmez.

### 1. Approved source commit'i sabitle

Final kod, legal metin, verifier/test/workflow ve yetkili sign-off'un bulunduğu
commit'i tam SHA ile sabitle. Bu commit approval JSON delta'sını henüz
içermemelidir:

```bash
APPROVED_SOURCE_SHA=$(git rev-parse HEAD)
git merge-base --is-ancestor "$APPROVED_SOURCE_SHA" origin/main
```

`docs/legal/legal-release-approval.json` schema v2 kullanmalı;
`source_commit_sha` tam bu SHA, `legal_bundle_sha256` ve
`runtime_surface_sha256` adım 0'daki güncel değerler olmalıdır. Acceptance
version, release tag, gerçek approver identity ve kalıcı evidence URL/URN'leri
aynı approved source'a bağlanır.

### 2. Yalnız approval JSON delta commit'ini oluştur

Approved source'tan sonra sadece
`docs/legal/legal-release-approval.json` değiştirilir. Stage ettikten sonra
delta'yı fail-closed doğrula:

```bash
git add docs/legal/legal-release-approval.json
APPROVAL_DIFF=$(git diff --cached --name-only "$APPROVED_SOURCE_SHA")
test "$APPROVAL_DIFF" = "docs/legal/legal-release-approval.json"
python3 tool/verify_legal_release_approval.py \
  --approval docs/legal/legal-release-approval.json \
  --release-tag v0.2.0 \
  --source-sha "$APPROVED_SOURCE_SHA"
git commit -m "chore(release): approve v0.2.0"
```

Bu single-purpose commit normal korumalı main/PR akışından geçer. Main'e
geldikten sonra release commit'inin tam olarak bir parent'ı olduğunu, parent'ın
approved source olduğunu ve tek farkın approval JSON olduğunu yeniden doğrula:

```bash
RELEASE_COMMIT_SHA=$(git rev-parse HEAD)
test "$(git rev-parse "${RELEASE_COMMIT_SHA}^")" = "$APPROVED_SOURCE_SHA"
test "$(git diff --name-only "$APPROVED_SOURCE_SHA" "$RELEASE_COMMIT_SHA")" = \
  "docs/legal/legal-release-approval.json"
```

Merge commit veya approval JSON yanında başka delta varsa production tag basma.

### 3. Annotated tag'i approval commit'ine koy

Production tag yalnız yukarıdaki `RELEASE_COMMIT_SHA` üzerine konur. RC kanalında
production approval delta'sı gerekmez; tag doğrudan yeşil `main` commit'ine konur.

```bash
git tag -a v0.2.0 "$RELEASE_COMMIT_SHA" -m "v0.2.0

✨ Portföy ekranı eklendi.
🐛 Grafik hatası düzeltildi.

=====LANG_SEPARATOR=====

✨ New portfolio screen.
🐛 Fixed the chart issue.
"
```

RC örneği aynı annotated formatla `v0.2.0-rc.1` adını kullanır.
RC legal gate'i atlar ve TestFlight/internal track'e yüklenebilir; yalnız
yetkili, sınırlı tester grubu içindir ve production hukuk onayı sayılmaz.

## Push öncesi ve sonrası

Tag object tipini, hedef commit'i ve mesajı lokal doğrula:

```bash
test "$(git cat-file -t v0.2.0)" = "tag"
git rev-parse v0.2.0^{commit}
git tag -l --format='%(contents)' v0.2.0
```

Push'tan hemen önce kullanıcıdan açık onay al. Ardından yalnız hedef tag'i
push'la ve workflow'u izle:

```bash
git push origin v0.2.0
gh run watch "$(gh run list --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Production environment required reviewer onayı repository ayarlarında gerçekten
kurulu olmalıdır; workflow'daki `environment` alanı tek başına onay sağlamaz.

Store build number her attempt için
`github.run_number * 100 + github.run_attempt` formülüyle üretilir. Aynı
immutable tag için workflow rerun yapılabilir; tag yeniden yaratılmaz.

## Hata ve kurtarma

- Push'lanmamış lokal tag hatalıysa düzeltmeden önce durumu tekrar göster ve
  kullanıcıdan onay al.
- Push'lanmış tag'i silmek, force-push etmek veya başka commit'e retarget
  etmek **KESİNLİKLE YASAKTIR**. Workflow'u gerekiyorsa reject/cancel et ve yeni
  bir SemVer tag'i için baştan protocol uygula. Production'da yeni tag adı yeni
  content-bound approval JSON delta commit'i gerektirir.
- Store upload başladıysa aynı version/tag'i yeniden üretme. Yeni SemVer kullan.

## Yasak

- Lightweight tag (`git tag v0.2.0`): workflow bunu fail-closed reddeder.
- Main'de olmayan veya exact SHA için CI kanıtı bulunmayan commit'i tag'lemek.
- Approval JSON ile birlikte başka dosya değiştiren production approval commit'i.
- Pushed tag delete, force update veya retarget.
- `git push --tags`: yalnız tek, açıkça onaylanmış tag push'lanır.
