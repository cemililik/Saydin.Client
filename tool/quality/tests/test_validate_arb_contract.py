import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "validate_arb_contract.py"
SPEC = importlib.util.spec_from_file_location("arb_contract", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
arb_contract = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(arb_contract)


class ArbContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "lib/l10n").mkdir(parents=True)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write(self, tr: dict, en: dict) -> None:
        for locale, value in (("tr", tr), ("en", en)):
            (self.root / f"lib/l10n/app_{locale}.arb").write_text(
                json.dumps(value), encoding="utf-8"
            )

    def test_matching_placeholder_contract_passes(self) -> None:
        metadata = {"placeholders": {"amount": {"type": "String"}}}
        self.write(
            {"@@locale": "tr", "value": "Değer {amount}", "@value": metadata},
            {"@@locale": "en", "value": "Value {amount}", "@value": metadata},
        )
        self.assertEqual(arb_contract.validate(self.root), 1)

    def test_missing_locale_key_fails(self) -> None:
        self.write({"@@locale": "tr", "value": "Değer"}, {"@@locale": "en"})
        with self.assertRaisesRegex(arb_contract.ArbContractError, "keys differ"):
            arb_contract.validate(self.root)

    def test_placeholder_type_drift_fails(self) -> None:
        self.write(
            {
                "@@locale": "tr",
                "value": "{amount}",
                "@value": {"placeholders": {"amount": {"type": "String"}}},
            },
            {
                "@@locale": "en",
                "value": "{amount}",
                "@value": {"placeholders": {"amount": {"type": "num"}}},
            },
        )
        with self.assertRaisesRegex(arb_contract.ArbContractError, "types differ"):
            arb_contract.validate(self.root)


if __name__ == "__main__":
    unittest.main()
