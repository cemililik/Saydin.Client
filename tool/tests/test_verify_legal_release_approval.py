import importlib.util
import json
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "verify_legal_release_approval.py"
SPEC = importlib.util.spec_from_file_location("legal_approval", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
legal_approval = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(legal_approval)


class LegalApprovalTest(unittest.TestCase):
    SOURCE_SHA = "0123456789abcdef0123456789abcdef01234567"
    CONTROLLER = {
        "legal_name": "Example Controller A.Ş.",
        "service_address": "Example Mahallesi No: 1 İstanbul",
        "formal_request_channel": "kvkk@example.test",
    }

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for relative in legal_approval.RUNTIME_SURFACE_REQUIRED_FILES:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"runtime fixture: {relative}\n", encoding="utf-8")
        for relative in legal_approval.LEGAL_FILES:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                "final approved legal text\n"
                + "\n".join(self.CONTROLLER.values())
                + "\n",
                encoding="utf-8",
            )
        version = (
            self.root
            / "lib/features/onboarding/domain/repositories/onboarding_repository.dart"
        )
        version.parent.mkdir(parents=True, exist_ok=True)
        version.write_text(
            "static const int current = 2;\n"
            f"static const String bundleSha256 = '{legal_approval.legal_bundle_hash(self.root)}';\n",
            encoding="utf-8",
        )
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        signoff.parent.mkdir(parents=True, exist_ok=True)
        signoff.write_text(
            "**Durum:** APPROVED\n"
            "- [x] Mandatory evidence completed — Kanıt: urn:test:evidence\n"
            "## 3. Onay kaydı\n"
            "| Rol | Ad / kimlik | Kanıt | Tarih | Sürüm / commit | Durum |\n"
            "|---|---|---|---|---|---|\n"
            "| Release owner | Reviewer | urn:test:evidence | 2026-08-18 | "
            "v1.2.3 | ONAYLANDI |\n"
            "**Nihai durum:** APPROVED\n"
            "**Onaylanan uygulama sürümü:** v1.2.3\n"
            "**Onaylanan metin tarihi:** 2026-08-18\n",
            encoding="utf-8",
        )
        self.approval_path = self.root / "approval.json"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def approval(self) -> dict:
        timestamp = (
            datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z")
        )
        return {
            "schema_version": 2,
            "status": "APPROVED",
            "release_tag": "v1.2.3",
            "source_commit_sha": self.SOURCE_SHA,
            "legal_bundle_sha256": legal_approval.legal_bundle_hash(self.root),
            "runtime_surface_sha256": legal_approval.runtime_surface_hash(self.root),
            "legal_acceptance_version": 2,
            "approved_at": timestamp,
            "controller": self.CONTROLLER,
            "approvals": [
                {
                    "role": role,
                    "name": f"Reviewer {index}",
                    "identity": f"reviewer-{index}@example.test",
                    "evidence": f"urn:test:approval:{index}",
                    "approved_at": timestamp,
                }
                for index, role in enumerate(sorted(legal_approval.REQUIRED_ROLES))
            ],
        }

    def write_approval(self, approval: dict) -> None:
        self.approval_path.write_text(json.dumps(approval), encoding="utf-8")

    def test_valid_commit_bound_approval_passes(self) -> None:
        self.write_approval(self.approval())
        legal_approval.verify(
            self.root,
            self.approval_path,
            "v1.2.3",
            self.SOURCE_SHA,
        )

    def test_different_release_commit_fails(self) -> None:
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "source_commit_sha"):
            legal_approval.verify(
                self.root,
                self.approval_path,
                "v1.2.3",
                "fedcba9876543210fedcba9876543210fedcba98",
            )

    def test_changed_legal_source_fails_hash_check(self) -> None:
        self.write_approval(self.approval())
        (self.root / legal_approval.LEGAL_FILES[0]).write_text(
            "changed after approval\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(legal_approval.ApprovalError, "sha256"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_missing_role_fails_closed(self) -> None:
        approval = self.approval()
        approval["approvals"].pop()
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "roles are missing"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_draft_marker_fails_even_with_approvals(self) -> None:
        source = self.root / legal_approval.LEGAL_FILES[0]
        source.write_text("Privacy Policy — Publication Draft\n", encoding="utf-8")
        approval = self.approval()
        approval["legal_bundle_sha256"] = legal_approval.legal_bundle_hash(self.root)
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "draft markers"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_expanded_draft_language_fails_even_without_title_marker(self) -> None:
        source = self.root / legal_approval.LEGAL_FILES[0]
        source.write_text(
            "Bu metin yayın için onaylanmış nihai politika değildir.\n",
            encoding="utf-8",
        )
        approval = self.approval()
        approval["legal_bundle_sha256"] = legal_approval.legal_bundle_hash(self.root)
        approval["runtime_surface_sha256"] = legal_approval.runtime_surface_hash(
            self.root
        )
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "draft markers"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_changed_runtime_privacy_surface_fails_hash_check(self) -> None:
        self.write_approval(self.approval())
        (self.root / "ios/Runner/Info.plist").write_text(
            "changed privacy declaration\n", encoding="utf-8"
        )
        with self.assertRaisesRegex(legal_approval.ApprovalError, "runtime_surface"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_approved_final_status_with_blocked_top_status_fails(self) -> None:
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        signoff.write_text(
            "**Durum:** BLOCKED\n## 3. Onay kaydı\n"
            "**Nihai durum:** APPROVED\n",
            encoding="utf-8",
        )
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "top status"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_unchecked_signoff_item_fails(self) -> None:
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        signoff.write_text(
            "**Durum:** APPROVED\n"
            "- [ ] Missing mandatory evidence\n"
            "## 3. Onay kaydı\n"
            "**Nihai durum:** APPROVED\n",
            encoding="utf-8",
        )
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "unchecked"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_pending_approval_record_placeholder_fails(self) -> None:
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        signoff.write_text(
            "**Durum:** APPROVED\n"
            "- [x] Evidence complete — Kanıt: urn:test:evidence\n"
            "## 3. Onay kaydı\n"
            "| Product owner | BEKLENİYOR | — | — | — | BEKLEMEDE |\n"
            "**Nihai durum:** APPROVED\n"
            "**Onaylanan uygulama sürümü:** v1.2.3\n"
            "**Onaylanan metin tarihi:** 2026-08-18\n",
            encoding="utf-8",
        )
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "placeholders"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_checked_item_without_inline_evidence_fails(self) -> None:
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        text = signoff.read_text(encoding="utf-8").replace(
            " — Kanıt: urn:test:evidence", ""
        )
        signoff.write_text(text, encoding="utf-8")
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "inline evidence"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_short_approver_name_fails(self) -> None:
        approval = self.approval()
        approval["approvals"][0]["name"] = "x"
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "name is a placeholder"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_duplicate_approver_identity_fails(self) -> None:
        approval = self.approval()
        approval["approvals"][1]["identity"] = approval["approvals"][0][
            "identity"
        ]
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "duplicate approval identity"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_approver_identity_must_have_a_verifiable_shape(self) -> None:
        approval = self.approval()
        approval["approvals"][0]["identity"] = "unverifiable identity"
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "email, @handle"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_approval_evidence_must_be_a_stable_reference(self) -> None:
        approval = self.approval()
        approval["approvals"][0]["evidence"] = "looks good"
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "https URL or URN"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_stale_1970_approval_timestamp_fails(self) -> None:
        approval = self.approval()
        approval["approved_at"] = "1970-01-01T00:00:00Z"
        for item in approval["approvals"]:
            item["approved_at"] = "1970-01-01T00:00:00Z"
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "older than"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_controller_identity_must_appear_in_every_legal_source(self) -> None:
        approval = self.approval()
        approval["controller"] = {
            **self.CONTROLLER,
            "legal_name": "Different Controller A.Ş.",
        }
        self.write_approval(approval)
        with self.assertRaisesRegex(legal_approval.ApprovalError, "not present verbatim"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )

    def test_signoff_release_version_must_match_artifact(self) -> None:
        signoff = self.root / "docs/legal/legal-release-signoff.md"
        signoff.write_text(
            signoff.read_text(encoding="utf-8").replace(
                "**Onaylanan uygulama sürümü:** v1.2.3",
                "**Onaylanan uygulama sürümü:** v9.9.9",
            ),
            encoding="utf-8",
        )
        self.write_approval(self.approval())
        with self.assertRaisesRegex(legal_approval.ApprovalError, "application version"):
            legal_approval.verify(
                self.root, self.approval_path, "v1.2.3", self.SOURCE_SHA
            )


if __name__ == "__main__":
    unittest.main()
