#!/usr/bin/env python3
"""Fail-closed project and patch line-coverage gate for Flutter LCOV."""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple


class CoverageError(ValueError):
    """Raised when coverage input or policy is invalid."""


class CoverageResult(NamedTuple):
    project_hit: int
    project_total: int
    patch_hit: int
    patch_total: int
    files_total: int

    @property
    def project_percent(self) -> float:
        return self.project_hit * 100 / self.project_total

    @property
    def patch_percent(self) -> float | None:
        if self.patch_total == 0:
            return None
        return self.patch_hit * 100 / self.patch_total


def _normalize_source(raw: str, repo_root: Path) -> str | None:
    path = Path(raw)
    if path.is_absolute():
        try:
            path = path.resolve().relative_to(repo_root)
        except ValueError:
            marker = f"{Path('/').as_posix()}lib/"
            normalized = raw.replace("\\", "/")
            if marker not in normalized:
                return None
            path = Path("lib") / normalized.split(marker, 1)[1]
    normalized = path.as_posix().removeprefix("./")
    return normalized if normalized.startswith("lib/") else None


def parse_lcov(lcov_path: Path, repo_root: Path) -> dict[str, dict[int, int]]:
    if not lcov_path.is_file():
        raise CoverageError(f"LCOV file is missing: {lcov_path}")
    records: dict[str, dict[int, int]] = {}
    source: str | None = None
    try:
        lines = lcov_path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise CoverageError(f"LCOV file is unreadable: {error}") from error
    for line in lines:
        if line.startswith("SF:"):
            source = _normalize_source(line[3:], repo_root)
            if source is not None:
                records.setdefault(source, {})
        elif source is not None and line.startswith("DA:"):
            fields = line[3:].split(",")
            if len(fields) < 2:
                raise CoverageError(f"Malformed LCOV DA record: {line}")
            try:
                line_number = int(fields[0])
                hits = int(fields[1])
            except ValueError as error:
                raise CoverageError(f"Malformed LCOV DA record: {line}") from error
            records[source][line_number] = max(
                hits, records[source].get(line_number, 0)
            )
        elif line == "end_of_record":
            source = None
    return records


def _read_policy(path: Path) -> dict[str, object]:
    try:
        policy = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CoverageError(f"Coverage policy is invalid: {error}") from error
    if not isinstance(policy, dict) or policy.get("schema_version") != 1:
        raise CoverageError("Coverage policy schema_version must be 1")
    for key in (
        "project_min_line_percent",
        "patch_min_line_percent",
        "target_line_percent",
    ):
        value = policy.get(key)
        if not isinstance(value, (int, float)) or not 0 <= value <= 100:
            raise CoverageError(f"Coverage policy {key} must be between 0 and 100")
    if policy["target_line_percent"] < policy["project_min_line_percent"]:
        raise CoverageError("Coverage target cannot be below the project floor")
    excluded = policy.get("excluded_paths")
    if not isinstance(excluded, list) or not all(
        isinstance(item, str) for item in excluded
    ):
        raise CoverageError("Coverage policy excluded_paths must be a string list")
    zero_sources = policy.get("allowed_zero_executable_sources", [])
    if not isinstance(zero_sources, list) or not all(
        isinstance(item, str) for item in zero_sources
    ):
        raise CoverageError(
            "Coverage policy allowed_zero_executable_sources must be a string list"
        )
    return policy


def _excluded(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def production_sources(repo_root: Path, excluded: list[str]) -> set[str]:
    return {
        path.relative_to(repo_root).as_posix()
        for path in (repo_root / "lib").rglob("*.dart")
        if not _excluded(path.relative_to(repo_root).as_posix(), excluded)
    }


HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def changed_lines(repo_root: Path, base_ref: str) -> dict[str, set[int]]:
    command = [
        "git",
        "diff",
        "--unified=0",
        "--no-ext-diff",
        base_ref,
        "--",
        "lib",
    ]
    result = subprocess.run(
        command,
        cwd=repo_root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise CoverageError(
            f"Could not compute patch against {base_ref!r}: {result.stderr.strip()}"
        )
    changes: dict[str, set[int]] = {}
    current: str | None = None
    for line in result.stdout.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
            changes.setdefault(current, set())
            continue
        match = HUNK.match(line)
        if current is None or match is None:
            continue
        start = int(match.group(1))
        count = int(match.group(2) or "1")
        changes[current].update(range(start, start + count))
    return changes


def evaluate(
    repo_root: Path,
    lcov_path: Path,
    policy_path: Path,
    base_ref: str | None = None,
) -> CoverageResult:
    policy = _read_policy(policy_path)
    excluded = list(policy["excluded_paths"])
    records = {
        path: lines
        for path, lines in parse_lcov(lcov_path, repo_root).items()
        if not _excluded(path, excluded)
    }
    expected = production_sources(repo_root, excluded)
    allowed_zero = set(policy.get("allowed_zero_executable_sources", []))
    stale_allowed = sorted(allowed_zero - expected)
    if stale_allowed:
        raise CoverageError(
            "Coverage policy has stale zero-executable sources: "
            + ", ".join(stale_allowed)
        )
    missing = sorted(expected - records.keys() - allowed_zero)
    if missing:
        preview = ", ".join(missing[:8])
        suffix = "" if len(missing) <= 8 else f" (+{len(missing) - 8} more)"
        raise CoverageError(
            "Production libraries are missing from LCOV; regenerate the coverage "
            f"import manifest: {preview}{suffix}"
        )

    project_total = sum(len(lines) for lines in records.values())
    project_hit = sum(
        1 for lines in records.values() for hits in lines.values() if hits > 0
    )
    if project_total == 0:
        raise CoverageError("Coverage denominator is zero")

    patch_total = 0
    patch_hit = 0
    if base_ref:
        for path, added in changed_lines(repo_root, base_ref).items():
            if _excluded(path, excluded) or path not in expected:
                continue
            if path not in records:
                # VM omits declaration-only libraries listed explicitly in
                # allowed_zero_executable_sources; they have no patch lines to gate.
                continue
            executable = records[path]
            coverable_added = added & executable.keys()
            patch_total += len(coverable_added)
            patch_hit += sum(1 for line in coverable_added if executable[line] > 0)

    result = CoverageResult(
        project_hit=project_hit,
        project_total=project_total,
        patch_hit=patch_hit,
        patch_total=patch_total,
        files_total=len(expected),
    )
    project_min = float(policy["project_min_line_percent"])
    if result.project_percent + 1e-9 < project_min:
        raise CoverageError(
            f"Project line coverage {result.project_percent:.2f}% is below "
            f"the {project_min:.2f}% baseline"
        )
    patch_min = float(policy["patch_min_line_percent"])
    if result.patch_percent is not None and result.patch_percent + 1e-9 < patch_min:
        raise CoverageError(
            f"Patch line coverage {result.patch_percent:.2f}% is below "
            f"the {patch_min:.2f}% gate"
        )
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--lcov", type=Path, default=Path("coverage/lcov.info"))
    parser.add_argument(
        "--policy", type=Path, default=Path("tool/quality/coverage_policy.json")
    )
    parser.add_argument("--base-ref")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    lcov = args.lcov if args.lcov.is_absolute() else repo_root / args.lcov
    policy = args.policy if args.policy.is_absolute() else repo_root / args.policy
    try:
        result = evaluate(repo_root, lcov, policy, args.base_ref)
    except CoverageError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(
        f"Project coverage: {result.project_percent:.2f}% "
        f"({result.project_hit}/{result.project_total}) across "
        f"{result.files_total} production libraries"
    )
    if result.patch_percent is not None:
        print(
            f"Patch coverage: {result.patch_percent:.2f}% "
            f"({result.patch_hit}/{result.patch_total})"
        )
    elif args.base_ref:
        print("Patch coverage: no changed executable Dart lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
