---
schema_version: 1
plan_id: saydin-master-review
lot_count: 24
cross_cutting_count: 6
output_schema_version: 1
---

# Saydın Client master review plan

This tracked plan is the reproducible source for project-wide audits. Review
session outputs are transient and remain under the ignored
`docs/code-reviews/master/` directory; this plan must never be copied back as a
locally edited source of truth.

## Operating rules

1. Record the reviewed commit SHA and dirty-worktree state before dispatch.
2. Read every tracked file assigned to a lot. Generated and binary files are
   inventoried and validated with the appropriate build/tool rather than
   silently skipped.
3. Review agents are read-only. They write only their assigned report artifact.
4. Select models according to risk and complexity; do not assume a particular
   vendor, model name, agent API or progress-tracking tool exists.
5. Bound concurrency to the runtime and repository constraints. Lots that edit
   nothing may run in parallel; verification begins only after their inputs are
   complete.
6. Every finding needs a stable ID, severity, exact location, evidence,
   failure/user impact, remediation and a false-positive assessment.
7. A verifier must independently classify each finding as confirmed, disputed
   or invalid before consolidation. Invalid findings remain in the audit trail.
8. Legal conclusions are technical consistency observations, not legal advice.

## Lot inventory

The launcher must find exactly these 24 lot IDs before dispatch.

| Lot | Primary scope | Required lenses |
|---|---|---|
| L01 | `lib/main.dart`, `lib/app.dart`, root navigation/bootstrap | startup, DI, lifecycle, accessibility |
| L02 | `lib/core/network/**` | protocol, retry, identity, validation, privacy |
| L03 | `lib/core/error/**`, `lib/core/observability/**` | semantics, PII, reporting, failure modes |
| L04 | `lib/core/storage/**`, `lib/core/platform/**`, `lib/core/lifecycle/**` | persistence, deletion, native boundary |
| L05 | `lib/core/constants/**`, `lib/core/di/**`, `lib/core/l10n/**` | single source, wiring, localization |
| L06 | `lib/core/theme/**`, `lib/core/widgets/**`, `lib/core/utils/**` | UX, a11y, precision, performance |
| L07 | `lib/features/account/**` | data rights, destructive UX, recovery |
| L08 | `lib/features/config/**` | cold start, entitlement, fallback |
| L09 | `lib/features/legal/**`, `lib/features/onboarding/**` | disclosure truth, consent record, a11y |
| L10 | `lib/features/settings/**`, `lib/features/favorites/**` | persistence, feedback, localization |
| L11 | `lib/features/what_if/data/**`, `lib/features/what_if/domain/**` | financial contract, API boundary, dates |
| L12 | `lib/features/what_if/presentation/**` | state races, validation, responsive UX |
| L13 | `lib/features/comparison/**` | financial correctness, async state, sharing |
| L14 | `lib/features/dca/**` | decimal precision, chronology, charts |
| L15 | `lib/features/portfolio/data/**`, `lib/features/portfolio/domain/**` | partial outcomes, precision, invariants |
| L16 | `lib/features/portfolio/presentation/**` | concurrency, accessibility, large layouts |
| L17 | `lib/features/scenarios/**` | serialization, replay, deletion, persistence |
| L18 | `lib/l10n/**`, app/store localization resources | parity, placeholders, generated drift |
| L19 | `test/core/**`, `test/l10n/**` | test oracle quality, failure coverage |
| L20 | `test/features/account/**` through `test/features/onboarding/**` | behavior and widget coverage |
| L21 | remaining `test/features/**`, `integration_test/**` if present | journeys, race coverage, determinism |
| L22 | `android/**` | permissions, transport, signing, release config |
| L23 | `ios/**` | ATS, privacy strings, signing, release config |
| L24 | `.github/**`, `.claude/**`, `tool/**`, root config, `docs/**`, assets | supply chain, automation, docs, branding |

If a path does not exist, the lot report records that fact and evaluates whether
the absence is itself a gap. Newly added files are assigned by the closest
scope; no tracked file may remain unaccounted for.

## Cross-cutting reviews

| ID | Lens | Minimum output |
|---|---|---|
| X01 | Security, privacy, KVKK/data rights | trust-boundary and data-flow map |
| X02 | Financial correctness | Decimal, date, partial/stale result audit |
| X03 | Product UX and accessibility | critical journey and adaptive-layout audit |
| X04 | Performance and reliability | concurrency, caching, lifecycle, retry audit |
| X05 | Documentation and localization consistency | code/workflow/docs and TR/EN parity audit |
| X06 | Architecture, tests and delivery | dependency, coverage and release-gate audit |

Cross-cutting reports identify systemic patterns. A one-location defect belongs
in its lot report unless its impact crosses trust or release boundaries.

## Report schema

Every lot and cross-cutting report starts with:

```yaml
---
schema_version: 1
reviewed_sha: <40-hex commit>
review_id: <L01..L24 or X01..X06>
status: draft
reviewer_runtime: <runtime/model or unknown>
files_expected: <count>
files_reviewed: <count>
---
```

Each finding uses this shape:

```markdown
### <review-id>-F<number> — <P0|P1|P2|P3> — <title>

- Location: `path:line`
- Category: `<lens>`
- Evidence: <observed behavior and relevant contract>
- Impact: <concrete failure or user impact>
- Remediation: <testable change>
- False-positive check: <alternative explanation assessed>
```

Reports also contain `Files reviewed`, `Clean controls`, `Open questions` and
`Verification notes` sections. A report cannot be marked complete when
`files_reviewed != files_expected`.

## Verification and consolidation

The independent verifier reopens each cited location and writes one of:

- `CONFIRMED`: evidence and severity are supported;
- `DISPUTED`: evidence is real but interpretation/severity needs a reasoned
  correction;
- `INVALID`: claim cannot be reproduced, with the disproving evidence.

The consolidator consumes only verified reports, preserves traceability to all
source IDs, merges duplicates without losing affected locations, and produces:

1. an executive risk summary;
2. severity-sorted findings;
3. positive controls;
4. a critical-to-low remediation plan with dependencies;
5. external decisions and unverified assumptions;
6. a finding-to-test acceptance matrix.

## Completion checks

- All 24 lots and six cross-cutting reports exist and match the reviewed SHA.
- File inventory has no unassigned tracked path.
- Every finding has a verifier result.
- Consolidation contains no unverified or silently deleted finding.
- Session artifacts remain outside tracked product documentation.
