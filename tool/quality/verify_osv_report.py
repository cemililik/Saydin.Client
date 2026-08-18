#!/usr/bin/env python3
"""Apply a fail-closed, severity-aware policy to osv-scanner JSON output."""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path


class OsvPolicyError(ValueError):
    """Raised for scanner/report failures or blocking vulnerabilities."""


CVSS_METRICS = {
    "AV": {"N": 0.85, "A": 0.62, "L": 0.55, "P": 0.2},
    "AC": {"L": 0.77, "H": 0.44},
    "UI": {"N": 0.85, "R": 0.62},
    "CIA": {"H": 0.56, "L": 0.22, "N": 0.0},
}
SEVERITY_RANK = {"LOW": 1, "MODERATE": 2, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


def _round_up_1(value: float) -> float:
    return math.ceil(value * 10 - 1e-10) / 10


def _cvss3_score(vector: str) -> float | None:
    if not vector.startswith(("CVSS:3.0/", "CVSS:3.1/")):
        return None
    metrics = dict(
        part.split(":", 1) for part in vector.split("/")[1:] if ":" in part
    )
    required = {"AV", "AC", "PR", "UI", "S", "C", "I", "A"}
    if not required.issubset(metrics):
        return None
    try:
        scope_changed = metrics["S"] == "C"
        pr_weights = (
            {"N": 0.85, "L": 0.68, "H": 0.5}
            if scope_changed
            else {"N": 0.85, "L": 0.62, "H": 0.27}
        )
        exploitability = (
            8.22
            * CVSS_METRICS["AV"][metrics["AV"]]
            * CVSS_METRICS["AC"][metrics["AC"]]
            * pr_weights[metrics["PR"]]
            * CVSS_METRICS["UI"][metrics["UI"]]
        )
        impact_subscore = 1 - (
            (1 - CVSS_METRICS["CIA"][metrics["C"]])
            * (1 - CVSS_METRICS["CIA"][metrics["I"]])
            * (1 - CVSS_METRICS["CIA"][metrics["A"]])
        )
    except KeyError:
        return None
    impact = (
        7.52 * (impact_subscore - 0.029)
        - 3.25 * (impact_subscore - 0.02) ** 15
        if scope_changed
        else 6.42 * impact_subscore
    )
    if impact <= 0:
        return 0.0
    base = min(1.08 * (impact + exploitability), 10) if scope_changed else min(
        impact + exploitability, 10
    )
    return _round_up_1(base)


def _score_severity(value: object) -> float | None:
    if not isinstance(value, str):
        return None
    try:
        numeric = float(value)
    except ValueError:
        return _cvss3_score(value)
    return numeric if 0 <= numeric <= 10 else None


def vulnerability_score(vulnerability: dict[str, object]) -> float | None:
    scores: list[float] = []
    for container_name in ("database_specific", "ecosystem_specific"):
        container = vulnerability.get(container_name)
        if isinstance(container, dict):
            severity = container.get("severity")
            if isinstance(severity, str) and severity.upper() in SEVERITY_RANK:
                rank = SEVERITY_RANK[severity.upper()]
                scores.append({1: 3.9, 2: 6.9, 3: 8.9, 4: 10.0}[rank])
    severity_entries = vulnerability.get("severity", [])
    if isinstance(severity_entries, list):
        for entry in severity_entries:
            if isinstance(entry, dict):
                score = _score_severity(entry.get("score"))
                if score is not None:
                    scores.append(score)
    return max(scores) if scores else None


def _vulnerabilities(report: object) -> list[dict[str, object]]:
    if not isinstance(report, dict) or not isinstance(report.get("results"), list):
        raise OsvPolicyError("OSV report must contain a results list")
    found: dict[str, dict[str, object]] = {}
    for result in report["results"]:
        if not isinstance(result, dict) or not isinstance(result.get("packages"), list):
            raise OsvPolicyError("OSV result packages must be a list")
        for package in result["packages"]:
            if not isinstance(package, dict):
                raise OsvPolicyError("OSV package entry must be an object")
            vulnerabilities = package.get("vulnerabilities", [])
            if not isinstance(vulnerabilities, list):
                raise OsvPolicyError("OSV vulnerabilities must be a list")
            for vulnerability in vulnerabilities:
                if not isinstance(vulnerability, dict):
                    raise OsvPolicyError("OSV vulnerability must be an object")
                identifier = vulnerability.get("id")
                if not isinstance(identifier, str) or not identifier:
                    raise OsvPolicyError("OSV vulnerability id is missing")
                found[identifier] = vulnerability
    return list(found.values())


def verify(report_path: Path, threshold: float = 7.0) -> tuple[list[str], list[str]]:
    if not report_path.is_file():
        raise OsvPolicyError(
            "OSV JSON report is missing; scanner failure cannot be treated as clean"
        )
    try:
        report = json.loads(report_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise OsvPolicyError(f"OSV JSON report is invalid: {error}") from error
    blocking: list[str] = []
    non_blocking: list[str] = []
    for vulnerability in _vulnerabilities(report):
        identifier = str(vulnerability["id"])
        score = vulnerability_score(vulnerability)
        if score is None:
            blocking.append(f"{identifier} (unknown severity; fail-closed)")
        elif score >= threshold:
            blocking.append(f"{identifier} (CVSS {score:.1f})")
        else:
            non_blocking.append(f"{identifier} (CVSS {score:.1f})")
    if blocking:
        raise OsvPolicyError("blocking vulnerabilities: " + ", ".join(blocking))
    return blocking, non_blocking


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    parser.add_argument("--threshold", type=float, default=7.0)
    parser.add_argument("--summary", type=Path)
    args = parser.parse_args()
    summary = ["## Dependency vulnerability policy", ""]
    try:
        _, non_blocking = verify(args.report, args.threshold)
    except OsvPolicyError as error:
        summary.append(f"❌ {error}")
        if args.summary is not None:
            args.summary.write_text("\n".join(summary) + "\n", encoding="utf-8")
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if non_blocking:
        summary.append("⚠️ Non-blocking findings below the high-severity threshold:")
        summary.extend(f"- {item}" for item in non_blocking)
    else:
        summary.append("✅ No dependency vulnerabilities found.")
    if args.summary is not None:
        args.summary.write_text("\n".join(summary) + "\n", encoding="utf-8")
    print(summary[-1])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
