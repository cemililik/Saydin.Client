#!/usr/bin/env python3
"""Small deterministic secret guard; CI also runs gitleaks over Git history."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


PATTERNS = {
    "private-key": re.compile(
        r"-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----"
    ),
    "github-token": re.compile(r"\bgh(?:p|o|u|s|r)_[A-Za-z0-9]{30,}\b"),
    "aws-access-key": re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    "slack-token": re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    "generic-secret": re.compile(
        r"(?i)\b(?:api[_-]?key|client[_-]?secret|auth[_-]?token|password)\b"
        r"\s*[:=]\s*['\"]?([A-Za-z0-9_./+=-]{20,})"
    ),
}
PLACEHOLDER = re.compile(
    r"(?i)(?:placeholder|example|sample|dummy|fake|redacted|changeme|"
    r"your[_-]|<[^>]+>|\$\{\{|secrets\.)"
)
MAX_TEXT_BYTES = 2_000_000


class SecretScanError(ValueError):
    """Raised when a target cannot be enumerated safely."""


def parse_tracked_paths(raw_paths: bytes, repo_root: Path) -> list[Path]:
    paths = []
    for raw in raw_paths.split(b"\0"):
        if not raw:
            continue
        relative = Path(raw.decode("utf-8"))
        if relative.is_absolute() or ".." in relative.parts:
            raise SecretScanError(f"Unsafe tracked path: {relative}")
        paths.append(repo_root / relative)
    return paths


def scan(paths: list[Path], repo_root: Path) -> list[str]:
    findings: list[str] = []
    for path in paths:
        if (
            path.is_symlink()
            or not path.is_file()
            or path.stat().st_size > MAX_TEXT_BYTES
        ):
            continue
        data = path.read_bytes()
        if b"\0" in data:
            continue
        text = data.decode("utf-8", errors="replace")
        relative = path.relative_to(repo_root).as_posix()
        for line_number, line in enumerate(text.splitlines(), start=1):
            for name, pattern in PATTERNS.items():
                match = pattern.search(line)
                if match is None:
                    continue
                candidate = match.group(0)
                if PLACEHOLDER.search(candidate):
                    continue
                findings.append(f"{relative}:{line_number}: {name}")
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--path", type=Path, action="append")
    parser.add_argument("--paths-from-stdin", action="store_true")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    try:
        if args.path and args.paths_from_stdin:
            raise SecretScanError("Use either --path or --paths-from-stdin")
        if args.path:
            paths = [
                path if path.is_absolute() else repo_root / path for path in args.path
            ]
        elif args.paths_from_stdin:
            paths = parse_tracked_paths(sys.stdin.buffer.read(), repo_root)
        else:
            raise SecretScanError("Provide --path or --paths-from-stdin")
        findings = scan(paths, repo_root)
    except (OSError, SecretScanError, ValueError) as error:
        print(f"ERROR: secret scan could not complete: {error}", file=sys.stderr)
        return 1
    if findings:
        print("ERROR: potential committed secrets detected:", file=sys.stderr)
        for finding in findings:
            print(f"- {finding}", file=sys.stderr)
        return 1
    print(f"Tracked secret scan passed: {len(paths)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
