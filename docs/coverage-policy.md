# Coverage policy

Coverage is a regression signal, not a proxy for product correctness. The gate
is intentionally explicit about its denominator and current baseline so a low
number cannot be hidden by generated files or by libraries never loaded during
tests.

## Denominator

`test/coverage/all_production_libraries_test.dart` is generated from every
`lib/**/*.dart` source by `tool/quality/generate_coverage_imports.py`. Importing
the full source inventory makes unexecuted production libraries visible to the
Dart VM coverage collector. CI rejects a stale manifest before tests run.

Generated `app_localizations*.dart` implementations are excluded. Their source
ARB parity, locale metadata, placeholders and generated-file dirty state have
separate fail-closed gates. Declaration-only repository interfaces that the VM
omits from LCOV are listed explicitly as zero-executable sources in the policy;
any new omission fails until reviewed.

## Gates

The source of truth is `tool/quality/coverage_policy.json`:

- project line floor: **47.8%**;
- measured final full-inventory baseline on 2026-08-18: **49.16% (3927/7989)**;
- changed executable-line floor on pull requests: **50.0%**;
- staged target: **60.0%+**.

The project floor starts just below the final, twice-reproduced measured
baseline to avoid false failure from display rounding while preventing a
material regression. Raising
the floor requires a fresh full-suite measurement and must never reduce the
threshold. Codecov additionally uses `target: auto` with zero tolerance to flag
any parent-to-PR project decline and mirrors the 50% patch floor. The local
Python baseline gate is authoritative and fails when LCOV, policy, source
inventory or PR base evidence is unavailable. Making the asynchronous Codecov
status mandatory remains a repository-ruleset responsibility.

## Commands

```bash
python3 tool/quality/generate_coverage_imports.py --check
flutter test --coverage
python3 tool/quality/coverage_gate.py

# Pull-request equivalent
python3 tool/quality/coverage_gate.py --base-ref <base-commit-sha>
```

When a production Dart file is added or removed, regenerate and commit the
manifest:

```bash
python3 tool/quality/generate_coverage_imports.py
dart format test/coverage/all_production_libraries_test.dart
```

Threshold increases should follow meaningful tests of risk-bearing behavior,
not tests written only to execute lines.
