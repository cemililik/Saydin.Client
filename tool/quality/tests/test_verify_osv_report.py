import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "verify_osv_report.py"
SPEC = importlib.util.spec_from_file_location("osv_policy", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
osv_policy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(osv_policy)


class OsvPolicyTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.report = Path(self.temp.name) / "osv.json"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write(self, vulnerabilities: list[dict]) -> None:
        self.report.write_text(
            json.dumps(
                {"results": [{"packages": [{"vulnerabilities": vulnerabilities}]}]}
            ),
            encoding="utf-8",
        )

    def test_empty_report_passes(self) -> None:
        self.report.write_text('{"results": []}', encoding="utf-8")
        self.assertEqual(osv_policy.verify(self.report), ([], []))

    def test_low_severity_is_reported_but_not_blocking(self) -> None:
        self.write([{"id": "OSV-LOW", "database_specific": {"severity": "LOW"}}])
        _, warnings = osv_policy.verify(self.report)
        self.assertEqual(len(warnings), 1)

    def test_high_cvss_blocks(self) -> None:
        self.write(
            [
                {
                    "id": "OSV-HIGH",
                    "severity": [
                        {
                            "type": "CVSS_V3",
                            "score": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
                        }
                    ],
                }
            ]
        )
        with self.assertRaisesRegex(osv_policy.OsvPolicyError, "OSV-HIGH"):
            osv_policy.verify(self.report)

    def test_unknown_severity_blocks_fail_closed(self) -> None:
        self.write([{"id": "OSV-UNKNOWN"}])
        with self.assertRaisesRegex(osv_policy.OsvPolicyError, "unknown severity"):
            osv_policy.verify(self.report)

    def test_missing_report_is_not_clean(self) -> None:
        with self.assertRaisesRegex(osv_policy.OsvPolicyError, "missing"):
            osv_policy.verify(self.report)


if __name__ == "__main__":
    unittest.main()
