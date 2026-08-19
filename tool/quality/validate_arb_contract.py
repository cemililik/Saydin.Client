#!/usr/bin/env python3
"""Validate locale parity and placeholder contracts for committed ARB files."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


PLACEHOLDER_NAME = re.compile(r"[A-Za-z][A-Za-z0-9_]*")


class ArbContractError(ValueError):
    """Raised when localization sources disagree."""


def _read_arb(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ArbContractError(f"{path}: invalid ARB JSON: {error}") from error
    if not isinstance(value, dict):
        raise ArbContractError(f"{path}: ARB root must be an object")
    return value


def _message_keys(arb: dict[str, object]) -> set[str]:
    return {key for key in arb if not key.startswith("@")}


def _referenced_placeholders(message: str) -> set[str]:
    """Return only top-level ICU arguments, ignoring nested plural branches."""
    names: set[str] = set()
    depth = 0
    index = 0
    while index < len(message):
        character = message[index]
        if character == "{":
            if depth == 0:
                match = PLACEHOLDER_NAME.match(message, index + 1)
                if match is not None:
                    names.add(match.group())
            depth += 1
        elif character == "}" and depth > 0:
            depth -= 1
        index += 1
    return names


def _placeholder_contract(
    arb: dict[str, object], key: str, path: Path
) -> dict[str, object]:
    message = arb.get(key)
    if not isinstance(message, str):
        raise ArbContractError(f"{path}: {key} must be a string")
    referenced = _referenced_placeholders(message)
    metadata = arb.get(f"@{key}", {})
    if not isinstance(metadata, dict):
        raise ArbContractError(f"{path}: @{key} metadata must be an object")
    placeholders = metadata.get("placeholders", {})
    if not isinstance(placeholders, dict):
        raise ArbContractError(f"{path}: @{key}.placeholders must be an object")
    declared = set(placeholders)
    if referenced != declared:
        raise ArbContractError(
            f"{path}: {key} placeholder mismatch; "
            f"message={sorted(referenced)}, metadata={sorted(declared)}"
        )
    contract: dict[str, object] = {}
    for name, definition in placeholders.items():
        if not isinstance(definition, dict):
            raise ArbContractError(
                f"{path}: @{key}.placeholders.{name} must be an object"
            )
        contract[name] = definition.get("type")
    return contract


def validate(repo_root: Path) -> int:
    paths = {
        "tr": repo_root / "lib/l10n/app_tr.arb",
        "en": repo_root / "lib/l10n/app_en.arb",
    }
    arbs = {locale: _read_arb(path) for locale, path in paths.items()}
    for locale, arb in arbs.items():
        if arb.get("@@locale") != locale:
            raise ArbContractError(
                f"{paths[locale]}: @@locale must be {locale!r}"
            )

    tr_keys = _message_keys(arbs["tr"])
    en_keys = _message_keys(arbs["en"])
    if tr_keys != en_keys:
        raise ArbContractError(
            "TR/EN message keys differ; "
            f"TR-only={sorted(tr_keys - en_keys)}, EN-only={sorted(en_keys - tr_keys)}"
        )

    for key in sorted(tr_keys):
        tr_contract = _placeholder_contract(arbs["tr"], key, paths["tr"])
        en_contract = _placeholder_contract(arbs["en"], key, paths["en"])
        if tr_contract != en_contract:
            raise ArbContractError(
                f"{key}: TR/EN placeholder names or types differ; "
                f"TR={tr_contract}, EN={en_contract}"
            )
    return len(tr_keys)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        count = validate(args.repo_root.resolve())
    except ArbContractError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"ARB contract verified: TR/EN parity for {count} messages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
