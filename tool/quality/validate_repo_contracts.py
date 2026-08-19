#!/usr/bin/env python3
"""Validate non-Dart agent, review-plan and documentation contracts."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


class RepoContractError(ValueError):
    """Raised when repository-local automation contracts drift."""


AGENT_FILES = (
    ".claude/agents/saydin-reviewer.md",
    ".claude/skills/develop-task/SKILL.md",
    ".claude/skills/feature-scaffold/SKILL.md",
    ".claude/skills/bloc-page/SKILL.md",
    ".claude/skills/yasak-check/SKILL.md",
)
FORBIDDEN_AGENT_PATTERNS = {
    "undefined Result return type": re.compile(r"Future\s*<\s*Result\s*<"),
    "undefined FailureOrSuccess return type": re.compile(r"FailureOrSuccess\s*<"),
    "undefined Result constructor": re.compile(r"Result\.(?:ok|err)\s*\("),
    "undefined error localization API": re.compile(r"\.localized\(context\)"),
    "monetary num recommendation": re.compile(
        r"(?i)(?:final\s+num\s+(?:amount|price|total|value)|"
        r"para\s+alanlar[\u0131i]\s+`?num|dahili\s+hesap\s+i\u00e7in\s+`?num)"
    ),
}
DEVICE_ID = re.compile(r"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b")
TUNNEL_URL = re.compile(
    r"https?://[^\s`<]+\.(?:ngrok-free\.(?:app|dev)|ngrok\.app|trycloudflare\.com)",
    re.IGNORECASE,
)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
RELEASE_SKILL_REQUIRED_PATTERNS = {
    "approved source SHA snapshot": re.compile(
        r"APPROVED_SOURCE_SHA=\$\(git rev-parse HEAD\)"
    ),
    "approval-only staged delta check": re.compile(
        r"git diff --cached --name-only [^\n]*APPROVED_SOURCE_SHA"
    ),
    "content-bound legal verifier": re.compile(
        r"verify_legal_release_approval\.py[\s\S]*?--source-sha[\s\S]*?"
        r"APPROVED_SOURCE_SHA"
    ),
    "legal sign-off source": re.compile(r"docs/legal/legal-release-signoff\.md"),
    "runtime privacy surface snapshot": re.compile(
        r"--print-runtime-surface-hash"
    ),
    "approval schema v2": re.compile(r"schema v2", re.IGNORECASE),
    "annotated tag command": re.compile(r"git tag -a\s+v\d+\.\d+\.\d+"),
    "immutable pushed-tag prohibition": re.compile(
        r"Push'lanmış tag'i[\s\S]{0,180}KESİNLİKLE YASAKTIR",
        re.IGNORECASE,
    ),
    "rerun-safe build number formula": re.compile(
        r"github\.run_number\s*\*\s*100\s*\+\s*github\.run_attempt"
    ),
}
RELEASE_SKILL_FORBIDDEN_PATTERNS = {
    "remote tag deletion command": re.compile(
        r"git\s+push[^\n]*(?:--delete|:refs/tags/)", re.IGNORECASE
    ),
    "tag force-retarget command": re.compile(
        r"git\s+tag[^\n]*(?:--force|(?:^|\s)-f(?:\s|$))", re.IGNORECASE
    ),
}


def _read_required(repo_root: Path, relative: str) -> str:
    path = repo_root / relative
    if not path.is_file():
        raise RepoContractError(f"required file is missing: {relative}")
    return path.read_text(encoding="utf-8")


def validate_agent_contracts(repo_root: Path) -> None:
    findings: list[str] = []
    for relative in AGENT_FILES:
        text = _read_required(repo_root, relative)
        if "docs/engineering/financial-error-contract.md" not in text:
            findings.append(f"{relative}: canonical financial/error contract link missing")
        for label, pattern in FORBIDDEN_AGENT_PATTERNS.items():
            if pattern.search(text):
                findings.append(f"{relative}: {label}")

    deploy = _read_required(repo_root, ".claude/skills/device-deploy/SKILL.md")
    if DEVICE_ID.search(deploy):
        findings.append("device-deploy skill contains a physical device identifier")
    if TUNNEL_URL.search(deploy):
        findings.append("device-deploy skill contains a concrete tunnel URL")
    if "SAYDIN_DEVICE_ID" not in deploy or "SAYDIN_API_BASE_URL" not in deploy:
        findings.append("device-deploy skill lacks explicit local session inputs")

    master = _read_required(repo_root, ".claude/skills/master-review/SKILL.md")
    for stale in (
        "docs/code-reviews/master/MASTER-REVIEW-PLAN.md",
        "TodoWrite",
        "claude-opus",
    ):
        if stale in master:
            findings.append(f"master-review skill contains runtime-specific/stale token: {stale}")

    if findings:
        raise RepoContractError("agent contract drift:\n- " + "\n- ".join(findings))


def validate_release_skill(repo_root: Path) -> None:
    relative = ".claude/skills/release/SKILL.md"
    text = _read_required(repo_root, relative)
    findings: list[str] = []

    for label, pattern in RELEASE_SKILL_REQUIRED_PATTERNS.items():
        if pattern.search(text) is None:
            findings.append(f"{relative}: missing {label}")
    for label, pattern in RELEASE_SKILL_FORBIDDEN_PATTERNS.items():
        if pattern.search(text) is not None:
            findings.append(f"{relative}: contains {label}")

    ordered_protocol = (
        "### 1. Approved source commit'i sabitle",
        "### 2. Yalnız approval JSON delta commit'ini oluştur",
        "### 3. Annotated tag'i approval commit'ine koy",
    )
    positions = [text.find(marker) for marker in ordered_protocol]
    if any(position < 0 for position in positions) or positions != sorted(positions):
        findings.append(
            f"{relative}: production order must be approved source -> "
            "approval-only commit -> annotated tag"
        )

    if findings:
        raise RepoContractError("release skill drift:\n- " + "\n- ".join(findings))


def validate_release_workflow(repo_root: Path) -> None:
    relative = ".github/workflows/release.yml"
    text = _read_required(repo_root, relative)
    findings: list[str] = []

    mutable_checkout = re.compile(
        r"^\s*ref:\s*\$\{\{\s*needs\.guard\.outputs\.tag\s*\}\}\s*$",
        re.MULTILINE,
    )
    if mutable_checkout.search(text):
        findings.append(f"{relative}: downstream checkout uses mutable tag ref")

    exact_checkout = re.compile(
        r"^\s*ref:\s*\$\{\{\s*needs\.guard\.outputs\.tag_sha\s*\}\}\s*$",
        re.MULTILINE,
    )
    if len(exact_checkout.findall(text)) < 4:
        findings.append(f"{relative}: code/legal/evidence checkouts are not exact-SHA pinned")

    required_literals = {
        "guarded tag message snapshot": "tag_message_b64:",
        "guarded annotated tag object": "tag_object_sha:",
        "late tag mapping verification": "Re-verify immutable tag and existing release binding",
        "exact GitHub Release target": (
            "target_commitish: ${{ needs.guard.outputs.tag_sha }}"
        ),
        "exact evidence source": "SOURCE_SHA: ${{ needs.guard.outputs.tag_sha }}",
    }
    for label, literal in required_literals.items():
        if literal not in text:
            findings.append(f"{relative}: missing {label}")

    if findings:
        raise RepoContractError("release workflow drift:\n- " + "\n- ".join(findings))


def validate_error_contract_docs(repo_root: Path) -> None:
    relative = "docs/architecture.md"
    text = _read_required(repo_root, relative)
    if re.search(
        r"feature-disabled[^\n]*çıplak 403[^\n]*(?:buraya|FeatureDisabledError)",
        text,
        re.IGNORECASE,
    ):
        raise RepoContractError(
            f"{relative}: bare 403 must not imply feature-disabled semantics"
        )
    if not re.search(
        r"Çıplak 403[\s\S]{0,220}ForbiddenError[\s\S]{0,220}"
        r"explicit[^\n]*feature-disabled",
        text,
        re.IGNORECASE,
    ):
        raise RepoContractError(
            f"{relative}: explicit feature-disabled versus bare-403 contract missing"
        )


def validate_master_plan(repo_root: Path) -> None:
    relative = "docs/review/MASTER-REVIEW-PLAN.md"
    text = _read_required(repo_root, relative)
    if not re.search(r"^schema_version:\s*1\s*$", text, re.MULTILINE):
        raise RepoContractError("master review plan schema_version must be 1")
    declared = re.search(r"^lot_count:\s*(\d+)\s*$", text, re.MULTILINE)
    if declared is None or int(declared.group(1)) != 24:
        raise RepoContractError("master review plan lot_count must be 24")
    lot_ids = re.findall(r"^\|\s*(L\d{2})\s*\|", text, re.MULTILINE)
    expected = [f"L{index:02d}" for index in range(1, 25)]
    if lot_ids != expected:
        raise RepoContractError(
            f"master review plan lots must be exactly L01..L24; found {lot_ids}"
        )


def validate_markdown_links(repo_root: Path) -> int:
    checked = 0
    broken: list[str] = []
    for path in repo_root.rglob("*.md"):
        relative = path.relative_to(repo_root)
        if any(part in {".git", ".dart_tool", "build", "code-reviews"} for part in relative.parts):
            continue
        text = path.read_text(encoding="utf-8")
        in_fence = False
        for line_number, line_text in enumerate(text.splitlines(), start=1):
            if line_text.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for match in MARKDOWN_LINK.finditer(line_text):
                target = match.group(1).strip()
                if target.startswith("<") and target.endswith(">"):
                    target = target[1:-1]
                target = target.split(maxsplit=1)[0]
                if not target or target.startswith(("#", "http://", "https://", "mailto:")):
                    continue
                target = target.split("#", 1)[0]
                resolved = (path.parent / target).resolve()
                checked += 1
                if not resolved.exists():
                    broken.append(
                        f"{relative.as_posix()}:{line_number} -> {target}"
                    )
    if broken:
        raise RepoContractError("broken local Markdown links:\n- " + "\n- ".join(broken))
    return checked


def validate_review_bots(repo_root: Path) -> None:
    coderabbit = _read_required(repo_root, ".coderabbit.yaml")
    sourcery = _read_required(repo_root, ".sourcery.yaml")
    findings = []
    for branch in ("main", "development"):
        if not re.search(rf"^\s*-\s*{branch}\s*$", coderabbit, re.MULTILINE):
            findings.append(f"CodeRabbit base branch missing: {branch}")
    if re.search(r"!docs/\*\*", coderabbit):
        findings.append("CodeRabbit still excludes docs/**")
    for critical_path in ("docs/legal/**", ".github/workflows/**", ".claude/**"):
        if f'path: "{critical_path}"' not in coderabbit:
            findings.append(f"CodeRabbit critical path instruction missing: {critical_path}")
    if re.search(r'[-\s]["\']?docs/\*\*', sourcery):
        findings.append("Sourcery still excludes docs/**")
    if findings:
        raise RepoContractError("review bot drift:\n- " + "\n- ".join(findings))


def validate(repo_root: Path) -> int:
    validate_agent_contracts(repo_root)
    validate_release_skill(repo_root)
    validate_release_workflow(repo_root)
    validate_error_contract_docs(repo_root)
    validate_master_plan(repo_root)
    validate_review_bots(repo_root)
    return validate_markdown_links(repo_root)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        links = validate(args.repo_root.resolve())
    except (OSError, RepoContractError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"Repository contracts verified; {links} local Markdown links checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
