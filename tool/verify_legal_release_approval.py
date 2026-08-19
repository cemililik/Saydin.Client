#!/usr/bin/env python3
"""Fail-closed verification for production legal/privacy approval."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path


LEGAL_FILES = (
    "lib/features/legal/data/sources/privacy_policy_tr.dart",
    "lib/features/legal/data/sources/privacy_policy_en.dart",
    "lib/features/legal/data/sources/kvkk_disclosure_tr.dart",
    "lib/features/legal/data/sources/kvkk_disclosure_en.dart",
)
RUNTIME_SURFACE_REQUIRED_FILES = (
    "lib/main.dart",
    "lib/app.dart",
    "lib/core/di/injection.dart",
    "lib/core/network/device_id_interceptor.dart",
    "lib/core/observability/sentry_pii_scrubber.dart",
    "lib/core/storage/secure_storage_factory.dart",
    "lib/core/utils/share_card_renderer.dart",
    "lib/core/widgets/share_preview_sheet.dart",
    "lib/features/account/data/repositories/account_data_repository_impl.dart",
    "lib/features/onboarding/domain/repositories/onboarding_repository.dart",
    "lib/features/scenarios/data/repositories/scenarios_repository_impl.dart",
    "lib/l10n/app_tr.arb",
    "lib/l10n/app_en.arb",
    "android/app/src/main/AndroidManifest.xml",
    "ios/Runner/Info.plist",
    "pubspec.yaml",
    "pubspec.lock",
)
RUNTIME_SURFACE_GLOBS = (
    "lib/**/*.dart",
    "android/app/src/main/res/xml/*.xml",
    "ios/Runner/Info*.plist",
    "ios/Runner/*.lproj/InfoPlist.strings",
)
REQUIRED_ROLES = {
    "product_owner",
    "backend_owner",
    "security_privacy",
    "legal_dpo",
    "release_owner",
}
PLACEHOLDERS = {"", "pending", "bekleniyor", "tbd", "todo", "n/a", "-"}
MAX_APPROVAL_AGE = timedelta(days=30)
DRAFT_MARKERS = tuple(
    re.compile(pattern, re.IGNORECASE)
    for pattern in (
        r"\btaslak\b",
        r"\bdraft\b",
        r"\bşablon\b",
        r"\btemplate\b",
        r"\b(?:TBD|TODO|PENDING|BEKLENİYOR)\b",
        r"doğrulanmadan",
        r"Yayın Taslağı",
        r"Publication Draft",
        r"Taslak Durumu",
        r"Draft Status",
        r"yayın için onaylanmış[^.\n]*değildir",
        r"not an approved(?: final)? (?:policy|disclosure|publication copy)",
        r"uygulama(?: mağazasına)?[^.\n]*yayınlanmamalıdır",
        r"(?:app|application)[^.\n]*must not be published",
        r"(?:metin|politika)[^.\n]*nihai değildir",
        r"(?:text|policy)[^.\n]*not final",
    )
)


class ApprovalError(ValueError):
    pass


def legal_bundle_hash(repo_root: Path) -> str:
    digest = hashlib.sha256()
    for relative in LEGAL_FILES:
        path = repo_root / relative
        if not path.is_file():
            raise ApprovalError(f"Legal source is missing: {relative}")
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def _runtime_surface_paths(repo_root: Path) -> list[Path]:
    missing = [
        relative
        for relative in RUNTIME_SURFACE_REQUIRED_FILES
        if not (repo_root / relative).is_file()
    ]
    if missing:
        raise ApprovalError(f"Runtime/privacy source is missing: {missing}")

    paths = {repo_root / relative for relative in RUNTIME_SURFACE_REQUIRED_FILES}
    for pattern in RUNTIME_SURFACE_GLOBS:
        paths.update(path for path in repo_root.glob(pattern) if path.is_file())
    return sorted(paths, key=lambda path: path.relative_to(repo_root).as_posix())


def runtime_surface_hash(repo_root: Path) -> str:
    """Hash production Dart, privacy strings, platform declarations and deps."""

    digest = hashlib.sha256(b"saydin-runtime-privacy-surface-v1\0")
    for path in _runtime_surface_paths(repo_root):
        relative = path.relative_to(repo_root).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def current_legal_version(repo_root: Path) -> int:
    path = (
        repo_root
        / "lib/features/onboarding/domain/repositories/onboarding_repository.dart"
    )
    if not path.is_file():
        raise ApprovalError(f"Legal version source is missing: {path}")
    match = re.search(r"static const int current\s*=\s*(\d+)\s*;", path.read_text())
    if match is None:
        raise ApprovalError("LegalAcceptanceVersion.current could not be read")
    return int(match.group(1))


def runtime_legal_bundle_hash(repo_root: Path) -> str:
    path = (
        repo_root
        / "lib/features/onboarding/domain/repositories/onboarding_repository.dart"
    )
    match = re.search(
        r"static const String bundleSha256\s*=\s*'([a-f0-9]{64})'\s*;",
        path.read_text(),
    )
    if match is None:
        raise ApprovalError("LegalAcceptanceVersion.bundleSha256 could not be read")
    return match.group(1)


def _require_utc_timestamp(value: object, field: str) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ApprovalError(f"{field} must be an ISO-8601 UTC timestamp")
    try:
        parsed = datetime.fromisoformat(value.removesuffix("Z") + "+00:00")
    except ValueError as error:
        raise ApprovalError(f"{field} must be an ISO-8601 UTC timestamp") from error
    if parsed > datetime.now(timezone.utc) + timedelta(minutes=5):
        raise ApprovalError(f"{field} cannot be in the future")
    if parsed < datetime.now(timezone.utc) - MAX_APPROVAL_AGE:
        raise ApprovalError(f"{field} is older than {MAX_APPROVAL_AGE.days} days")
    return parsed


def _require_non_placeholder_text(
    value: object,
    field: str,
    *,
    minimum_length: int = 3,
) -> str:
    if not isinstance(value, str):
        raise ApprovalError(f"{field} is required")
    normalized = value.strip()
    if (
        len(normalized) < minimum_length
        or normalized.casefold() in PLACEHOLDERS
        or "<" in normalized
        or ">" in normalized
    ):
        raise ApprovalError(f"{field} is a placeholder")
    return normalized


def _verify_signoff(repo_root: Path, release_tag: str) -> None:
    signoff_path = repo_root / "docs/legal/legal-release-signoff.md"
    if not signoff_path.is_file():
        raise ApprovalError("legal release sign-off is missing")

    signoff = signoff_path.read_text(encoding="utf-8")
    top_status = re.search(r"^\*\*Durum:\*\*\s*(.+?)\s*$", signoff, re.MULTILINE)
    final_status = re.search(
        r"^\*\*Nihai durum:\*\*\s*(.+?)\s*$", signoff, re.MULTILINE
    )
    if top_status is None or top_status.group(1).strip() != "APPROVED":
        raise ApprovalError("legal release sign-off top status is not APPROVED")
    if final_status is None or final_status.group(1).strip() != "APPROVED":
        raise ApprovalError("legal release sign-off final status is not APPROVED")
    if re.search(r"^\s*-\s*\[\s\]", signoff, re.MULTILINE):
        raise ApprovalError("legal release sign-off has unchecked mandatory items")

    for line in signoff.splitlines():
        if re.match(r"^\s*-\s*\[[xX]\]", line) and not re.search(
            r"\b(?:Kanıt|Evidence):", line
        ):
            raise ApprovalError("checked sign-off item is missing inline evidence")

    approval_section = re.search(
        r"^## 3\. Onay kaydı\s*$([\s\S]*?)(?=^##\s|\Z)",
        signoff,
        re.MULTILINE,
    )
    if approval_section is None:
        raise ApprovalError("legal release sign-off approval section is missing")
    if re.search(
        r"\b(?:BEKLENİYOR|PENDING|BEKLEMEDE)\b|\|\s*—\s*\|",
        approval_section.group(1),
        re.IGNORECASE,
    ):
        raise ApprovalError("legal release sign-off approval record has placeholders")

    release_match = re.search(
        r"^\*\*Onaylanan uygulama sürümü:\*\*\s*(\S+)\s*$",
        signoff,
        re.MULTILINE,
    )
    if release_match is None or release_match.group(1) != release_tag:
        raise ApprovalError("approved application version does not match release_tag")
    if re.search(
        r"^\*\*Onaylanan metin tarihi:\*\*\s*\d{4}-\d{2}-\d{2}\s*$",
        signoff,
        re.MULTILINE,
    ) is None:
        raise ApprovalError("approved legal-text date must be YYYY-MM-DD")


def _verify_controller_disclosure(
    repo_root: Path,
    approval: dict[str, object],
) -> None:
    controller = approval.get("controller")
    if not isinstance(controller, dict):
        raise ApprovalError("controller must be an object")
    fields = {
        "legal_name": _require_non_placeholder_text(
            controller.get("legal_name"), "controller.legal_name"
        ),
        "service_address": _require_non_placeholder_text(
            controller.get("service_address"),
            "controller.service_address",
            minimum_length=10,
        ),
        "formal_request_channel": _require_non_placeholder_text(
            controller.get("formal_request_channel"),
            "controller.formal_request_channel",
            minimum_length=5,
        ),
    }
    for relative in LEGAL_FILES:
        source = (repo_root / relative).read_text(encoding="utf-8")
        for field, value in fields.items():
            if value not in source:
                raise ApprovalError(
                    f"controller.{field} is not present verbatim in {relative}"
                )


def verify(
    repo_root: Path,
    approval_path: Path,
    release_tag: str,
    source_sha: str,
) -> None:
    if not re.fullmatch(r"v\d+\.\d+\.\d+", release_tag):
        raise ApprovalError("Production legal approval requires a vX.Y.Z tag")
    if not re.fullmatch(r"[0-9a-f]{40}", source_sha):
        raise ApprovalError("source SHA must be 40 lowercase hex characters")
    if not approval_path.is_file():
        raise ApprovalError(
            "Legal approval artifact is missing; production release is blocked"
        )

    try:
        approval = json.loads(approval_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ApprovalError(f"Legal approval artifact is unreadable: {error}") from error

    if approval.get("schema_version") != 2:
        raise ApprovalError("schema_version must be 2")
    if approval.get("status") != "APPROVED":
        raise ApprovalError("status must be APPROVED")
    if approval.get("release_tag") != release_tag:
        raise ApprovalError("release_tag does not match the production tag")
    if approval.get("source_commit_sha") != source_sha:
        raise ApprovalError(
            "source_commit_sha does not match the approved source commit"
        )

    combined_text = "\n".join(
        (repo_root / relative).read_text(encoding="utf-8") for relative in LEGAL_FILES
    )
    if any(marker.search(combined_text) for marker in DRAFT_MARKERS):
        raise ApprovalError("publication-draft markers remain in legal sources")

    actual_hash = legal_bundle_hash(repo_root)
    if approval.get("legal_bundle_sha256") != actual_hash:
        raise ApprovalError("legal_bundle_sha256 does not match the legal sources")
    if runtime_legal_bundle_hash(repo_root) != actual_hash:
        raise ApprovalError("runtime legal bundle hash does not match the legal sources")
    if approval.get("runtime_surface_sha256") != runtime_surface_hash(repo_root):
        raise ApprovalError(
            "runtime_surface_sha256 does not match the production privacy surface"
        )
    _verify_controller_disclosure(repo_root, approval)

    version = current_legal_version(repo_root)
    if approval.get("legal_acceptance_version") != version:
        raise ApprovalError(
            "legal_acceptance_version does not match LegalAcceptanceVersion.current"
        )

    _verify_signoff(repo_root, release_tag)

    artifact_approved_at = _require_utc_timestamp(
        approval.get("approved_at"), "approved_at"
    )
    approvals = approval.get("approvals")
    if not isinstance(approvals, list):
        raise ApprovalError("approvals must be a list")

    roles: set[str] = set()
    names: set[str] = set()
    identities: set[str] = set()
    approval_times: list[datetime] = []
    for index, item in enumerate(approvals):
        if not isinstance(item, dict):
            raise ApprovalError(f"approvals[{index}] must be an object")
        role = item.get("role")
        if role in roles:
            raise ApprovalError(f"duplicate approval role: {role}")
        if not isinstance(role, str):
            raise ApprovalError(f"approvals[{index}].role is required")
        name = _require_non_placeholder_text(
            item.get("name"), f"approvals[{index}].name"
        )
        identity = _require_non_placeholder_text(
            item.get("identity"), f"approvals[{index}].identity", minimum_length=4
        )
        if not re.fullmatch(
            r"(?:@[A-Za-z0-9](?:[A-Za-z0-9-]{1,38}[A-Za-z0-9])?|"
            r"[^@\s]+@[^@\s]+\.[^@\s]+|https://\S+)",
            identity,
        ):
            raise ApprovalError(
                f"approvals[{index}].identity must be an email, @handle or https URL"
            )
        evidence = _require_non_placeholder_text(
            item.get("evidence"), f"approvals[{index}].evidence", minimum_length=8
        )
        if not re.fullmatch(r"(?:https://\S+|urn:\S+)", evidence):
            raise ApprovalError(
                f"approvals[{index}].evidence must be an https URL or URN"
            )
        normalized_name = name.casefold()
        normalized_identity = identity.casefold()
        if normalized_name in names:
            raise ApprovalError(f"duplicate approval name: {name}")
        if normalized_identity in identities:
            raise ApprovalError(f"duplicate approval identity: {identity}")
        approved_at = _require_utc_timestamp(
            item.get("approved_at"), f"approvals[{index}].approved_at"
        )
        roles.add(role)
        names.add(normalized_name)
        identities.add(normalized_identity)
        approval_times.append(approved_at)

    missing = REQUIRED_ROLES - roles
    if missing:
        raise ApprovalError(f"required approval roles are missing: {sorted(missing)}")
    unexpected = roles - REQUIRED_ROLES
    if unexpected:
        raise ApprovalError(f"unexpected approval roles: {sorted(unexpected)}")
    if len(approvals) != len(REQUIRED_ROLES):
        raise ApprovalError("approvals must contain exactly one entry per required role")
    if approval_times and artifact_approved_at != max(approval_times):
        raise ApprovalError("approved_at must equal the latest role approval timestamp")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--approval", type=Path)
    parser.add_argument("--release-tag")
    parser.add_argument("--source-sha")
    parser.add_argument("--print-bundle-hash", action="store_true")
    parser.add_argument("--print-runtime-surface-hash", action="store_true")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()

    try:
        if args.print_bundle_hash:
            print(legal_bundle_hash(repo_root))
            return 0
        if args.print_runtime_surface_hash:
            print(runtime_surface_hash(repo_root))
            return 0
        if (
            args.approval is None
            or args.release_tag is None
            or args.source_sha is None
        ):
            parser.error(
                "--approval, --release-tag and --source-sha are required "
                "for verification"
            )
        approval_path = args.approval
        if not approval_path.is_absolute():
            approval_path = repo_root / approval_path
        verify(repo_root, approval_path, args.release_tag, args.source_sha)
    except ApprovalError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("Legal release approval verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
