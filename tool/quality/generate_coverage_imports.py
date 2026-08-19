#!/usr/bin/env python3
"""Generate imports that make every production Dart library visible to LCOV."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


OUTPUT = Path("test/coverage/all_production_libraries_test.dart")
HEADER = """// GENERATED FILE - DO NOT EDIT.
// Regenerate with: python3 tool/quality/generate_coverage_imports.py
//
// Importing every production library makes never-executed libraries visible to
// the Dart VM coverage collector. Generated localization implementations are
// excluded by the coverage policy and therefore intentionally omitted.
// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
"""


def production_libraries(repo_root: Path) -> list[Path]:
    libraries: list[Path] = []
    for path in (repo_root / "lib").rglob("*.dart"):
        relative = path.relative_to(repo_root)
        if relative.as_posix().startswith("lib/l10n/app_localizations"):
            continue
        libraries.append(relative)
    return sorted(libraries, key=lambda item: item.as_posix())


def render(repo_root: Path) -> str:
    imports = []
    for index, relative in enumerate(production_libraries(repo_root), start=1):
        package_path = relative.relative_to("lib").as_posix()
        statement = f"import 'package:saydin/{package_path}' as source_{index};"
        if len(statement) > 80:
            statement = (
                f"import 'package:saydin/{package_path}'\n"
                f"    as source_{index};"
            )
        imports.append(statement)
    body = "\n".join(imports)
    return (
        f"{HEADER}{body}\n\n"
        "void main() {\n"
        "  test('coverage manifest imports every production library', () {\n"
        "    expect(true, isTrue);\n"
        "  });\n"
        "}\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    repo_root = args.repo_root.resolve()
    output = repo_root / OUTPUT
    expected = render(repo_root)
    if args.check:
        actual = output.read_text(encoding="utf-8") if output.is_file() else ""
        actual_libraries = re.findall(r"import 'package:saydin/([^']+)'", actual)
        expected_libraries = [
            path.relative_to("lib").as_posix()
            for path in production_libraries(repo_root)
        ]
        if (
            not actual.startswith("// GENERATED FILE - DO NOT EDIT.")
            or actual_libraries != expected_libraries
        ):
            print(
                f"ERROR: {OUTPUT} is stale; run "
                "python3 tool/quality/generate_coverage_imports.py",
                file=sys.stderr,
            )
            return 1
        print(
            f"Coverage import manifest verified: "
            f"{len(production_libraries(repo_root))} libraries"
        )
        return 0
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(expected, encoding="utf-8")
    print(
        f"Generated {OUTPUT} with {len(production_libraries(repo_root))} libraries"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
