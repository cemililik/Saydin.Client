import importlib.util
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "validate_repo_contracts.py"
SPEC = importlib.util.spec_from_file_location("repo_contracts", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
repo_contracts = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(repo_contracts)


class RepoContractsTest(unittest.TestCase):
    VALID_RELEASE_SKILL = """\
docs/legal/legal-release-signoff.md
python3 tool/verify_legal_release_approval.py --print-runtime-surface-hash
schema v2
### 1. Approved source commit'i sabitle
APPROVED_SOURCE_SHA=$(git rev-parse HEAD)
### 2. Yalnız approval JSON delta commit'ini oluştur
git diff --cached --name-only "$APPROVED_SOURCE_SHA"
python3 tool/verify_legal_release_approval.py \\
  --source-sha "$APPROVED_SOURCE_SHA"
### 3. Annotated tag'i approval commit'ine koy
git tag -a v1.2.3 -m notes
Push'lanmış tag'i silmek veya retarget etmek KESİNLİKLE YASAKTIR.
github.run_number * 100 + github.run_attempt
"""

    def _write_release_skill(self, root: Path, text: str) -> None:
        skill = root / ".claude/skills/release/SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_text(text, encoding="utf-8")

    def test_broken_relative_markdown_link_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / "docs/readme.md").write_text(
                "[missing](./not-there.md)\n", encoding="utf-8"
            )
            with self.assertRaisesRegex(repo_contracts.RepoContractError, "broken"):
                repo_contracts.validate_markdown_links(root)

    def test_valid_relative_markdown_link_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / "docs/target.md").write_text("ok\n", encoding="utf-8")
            (root / "docs/readme.md").write_text(
                "[target](target.md#section)\n", encoding="utf-8"
            )
            self.assertEqual(repo_contracts.validate_markdown_links(root), 1)

    def test_undefined_result_syntax_is_rejected(self) -> None:
        pattern = repo_contracts.FORBIDDEN_AGENT_PATTERNS[
            "undefined Result return type"
        ]
        self.assertIsNotNone(pattern.search("Future<Result<Foo, AppError>> call();"))

    def test_decimal_contract_does_not_trigger_money_num_rule(self) -> None:
        pattern = repo_contracts.FORBIDDEN_AGENT_PATTERNS[
            "monetary num recommendation"
        ]
        self.assertIsNone(pattern.search("final Decimal amount;"))

    def test_valid_release_skill_protocol_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self._write_release_skill(root, self.VALID_RELEASE_SKILL)
            repo_contracts.validate_release_skill(root)

    def test_release_skill_remote_tag_deletion_command_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self._write_release_skill(
                root,
                self.VALID_RELEASE_SKILL
                + "git push origin --delete v1.2.3\n",
            )
            with self.assertRaisesRegex(
                repo_contracts.RepoContractError, "remote tag deletion"
            ):
                repo_contracts.validate_release_skill(root)

    def test_release_skill_wrong_build_formula_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            drifted = self.VALID_RELEASE_SKILL.replace(
                "github.run_number * 100 + github.run_attempt",
                "github.run_number",
            )
            self._write_release_skill(root, drifted)
            with self.assertRaisesRegex(
                repo_contracts.RepoContractError, "build number formula"
            ):
                repo_contracts.validate_release_skill(root)

    def test_architecture_bare_403_paywall_fallback_fails(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            architecture = root / "docs/architecture.md"
            architecture.parent.mkdir(parents=True)
            architecture.write_text(
                "feature-disabled: çıplak 403 de FeatureDisabledError olur\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(repo_contracts.RepoContractError, "bare 403"):
                repo_contracts.validate_error_contract_docs(root)


if __name__ == "__main__":
    unittest.main()
