# Dependency and secret security runbook

This runbook documents controls that are executable in the repository and the
remaining maintainer-owned update decisions. A green scan means no advisory
matched the checked dependency snapshot under the stated policy; it is not a
claim that the dependency graph is vulnerability-free.

## Automated controls

- `.github/workflows/ci.yml` runs OSV on pull requests, `development`/`main`
  pushes, manual dispatch and every Monday at 03:17 UTC.
- `tool/quality/verify_osv_report.py` blocks CVSS 7.0+ findings. A finding with
  no usable severity also blocks fail-closed; lower-severity findings remain in
  the job summary for triage.
- An unreadable/missing report is a scanner failure, never a clean result.
- Dependabot opens weekly GitHub Actions and Gradle minor/patch updates. It does
  not pretend that the unsupported `bundler` ecosystem updates CocoaPods.
- `tool/quality/scan_tracked_secrets.py` is a deterministic fast guard with
  negative fixtures. It receives the NUL-delimited tracked-file inventory from
  `git ls-files -z` over stdin, so untrusted filenames never become command
  arguments inside Python. Gitleaks scans Git history in CI. Signing keys,
  provisioning profiles, store archives, service-account inputs and dart-define
  JSON are ignored by `.gitignore`.

## Weekly triage

1. Open the newest scheduled `OSV Vulnerability Scan` result.
2. Confirm the JSON artifact exists even when the policy step fails.
3. For each advisory, record reachability, affected runtime/platform, fixed
   version, exploit prerequisites and owner. Do not downgrade an unknown
   severity just to make CI green.
4. Apply a compatible upgrade in `pubspec.yaml`/`pubspec.lock`, then run:

   ```bash
   flutter pub outdated
   flutter pub get
   flutter analyze --fatal-infos
   flutter test
   cd ios && pod install --repo-update && pod outdated
   ```

5. Review the `Podfile.lock` diff together with its owning Flutter plugin; iOS
   Pods are generally transitive outputs of Flutter plugins, not Bundler gems.
6. Re-run the OSV job and attach the passing run to the advisory/PR.

## Major security-sensitive upgrades

Do not automatically merge major upgrades of secure storage, observability,
networking or cryptography packages. The upgrade plan must include data-format
migration, rollback, corrupted-ciphertext behavior, device-ID continuity,
uninstall/reinstall semantics and real-device verification. In particular,
`flutter_secure_storage` major migration needs a staged plan before changing
the production storage format.

## Secret incident response

If a scanner finds a real credential, stop distribution, revoke/rotate it at
the provider, remove it from current source, assess Git history and artifacts,
and document the exposure window. Rewriting Git history does not revoke a
secret and must not be the first or only response.

## External controls

Repository code cannot configure required status checks by itself. Maintainers
must require the non-Dart, secret and OSV jobs in the repository ruleset and
must ensure scheduled workflows are not disabled. Release freshness coupling
remains dependent on that external governance until an approved release policy
explicitly requires the latest successful scheduled scan.
