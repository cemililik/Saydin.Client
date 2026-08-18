import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "generate_coverage_imports.py"
SPEC = importlib.util.spec_from_file_location("coverage_imports", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
coverage_imports = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(coverage_imports)


class CoverageImportsTest(unittest.TestCase):
    def test_render_is_sorted_and_excludes_generated_localizations(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for relative in (
                "lib/z.dart",
                "lib/a.dart",
                "lib/features/example/data/repositories/very_long_repository_name.dart",
                "lib/l10n/app_localizations.dart",
                "lib/l10n/app_localizations_tr.dart",
            ):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("", encoding="utf-8")
            rendered = coverage_imports.render(root)
            self.assertIn("package:saydin/a.dart", rendered)
            self.assertIn("package:saydin/z.dart", rendered)
            self.assertLess(rendered.index("a.dart"), rendered.index("z.dart"))
            self.assertNotIn("app_localizations", rendered)
            self.assertIn(
                "very_long_repository_name.dart'\n    as source_2;",
                rendered,
            )


if __name__ == "__main__":
    unittest.main()
