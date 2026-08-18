import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "scan_tracked_secrets.py"
SPEC = importlib.util.spec_from_file_location("secret_scan", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
secret_scan = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(secret_scan)


class SecretScanTest(unittest.TestCase):
    def test_private_key_fixture_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "leaked.pem"
            fixture.write_text(
                "-----BEGIN " + "PRIVATE KEY-----\nnot-a-real-key\n",
                encoding="utf-8",
            )
            findings = secret_scan.scan([fixture], root)
            self.assertEqual(findings, ["leaked.pem:1: private-key"])

    def test_placeholder_is_allowed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "safe.env"
            fixture.write_text(
                "CLIENT_SECRET=<your-client-secret-placeholder>\n", encoding="utf-8"
            )
            self.assertEqual(secret_scan.scan([fixture], root), [])

    def test_github_token_fixture_is_detected_without_storing_a_token(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "leaked.env"
            fixture.write_text("gh" + "p_" + "A" * 36 + "\n", encoding="utf-8")
            findings = secret_scan.scan([fixture], root)
            self.assertEqual(findings, ["leaked.env:1: github-token"])


if __name__ == "__main__":
    unittest.main()
