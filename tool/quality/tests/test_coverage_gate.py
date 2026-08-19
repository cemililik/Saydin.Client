import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "coverage_gate.py"
SPEC = importlib.util.spec_from_file_location("coverage_gate", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
coverage_gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(coverage_gate)


class CoverageGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "lib").mkdir()
        (self.root / "lib/a.dart").write_text("void a() {}\n", encoding="utf-8")
        self.lcov = self.root / "lcov.info"
        self.policy = self.root / "policy.json"
        self.policy.write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "project_min_line_percent": 50,
                    "patch_min_line_percent": 50,
                    "target_line_percent": 60,
                    "excluded_paths": [],
                }
            ),
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_project_threshold_passes(self) -> None:
        self.lcov.write_text(
            "SF:lib/a.dart\nDA:1,1\nDA:2,0\nend_of_record\n", encoding="utf-8"
        )
        result = coverage_gate.evaluate(self.root, self.lcov, self.policy)
        self.assertEqual(result.project_percent, 50)

    def test_missing_production_library_fails_closed(self) -> None:
        (self.root / "lib/b.dart").write_text("void b() {}\n", encoding="utf-8")
        self.lcov.write_text(
            "SF:lib/a.dart\nDA:1,1\nend_of_record\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(coverage_gate.CoverageError, "missing from LCOV"):
            coverage_gate.evaluate(self.root, self.lcov, self.policy)

    def test_missing_lcov_fails_closed(self) -> None:
        with self.assertRaisesRegex(coverage_gate.CoverageError, "missing"):
            coverage_gate.evaluate(self.root, self.lcov, self.policy)

    def test_project_regression_fails(self) -> None:
        self.lcov.write_text(
            "SF:lib/a.dart\nDA:1,0\nDA:2,0\nend_of_record\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(coverage_gate.CoverageError, "below"):
            coverage_gate.evaluate(self.root, self.lcov, self.policy)

    def test_patch_regression_fails(self) -> None:
        policy = json.loads(self.policy.read_text(encoding="utf-8"))
        policy["patch_min_line_percent"] = 75
        self.policy.write_text(json.dumps(policy), encoding="utf-8")
        self.lcov.write_text(
            "SF:lib/a.dart\nDA:1,1\nDA:2,0\nend_of_record\n", encoding="utf-8"
        )
        patch = self.root / "coverage.patch"
        patch.write_text(
            "+++ b/lib/a.dart\n@@ -0,0 +1,2 @@\n+void a() {}\n+void b() {}\n",
            encoding="utf-8",
        )
        with self.assertRaisesRegex(coverage_gate.CoverageError, "Patch"):
            coverage_gate.evaluate(self.root, self.lcov, self.policy, patch)

    def test_patch_parser_tracks_only_added_line_ranges(self) -> None:
        patch = "\n".join(
            (
                "+++ b/lib/a.dart",
                "@@ -1 +2,2 @@",
                "+first",
                "+second",
                "+++ b/lib/b.dart",
                "@@ -0,0 +9 @@",
                "+ninth",
            )
        )
        self.assertEqual(
            coverage_gate.parse_changed_lines(patch),
            {"lib/a.dart": {2, 3}, "lib/b.dart": {9}},
        )

    def test_missing_patch_file_fails_closed(self) -> None:
        self.lcov.write_text(
            "SF:lib/a.dart\nDA:1,1\nend_of_record\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(coverage_gate.CoverageError, "unreadable"):
            coverage_gate.evaluate(
                self.root, self.lcov, self.policy, self.root / "missing.patch"
            )


if __name__ == "__main__":
    unittest.main()
