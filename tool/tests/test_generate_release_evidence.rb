# frozen_string_literal: true

require "digest"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"

class GenerateReleaseEvidenceTest < Minitest::Test
  ROOT = Pathname(__dir__).join("../..").expand_path
  SCRIPT = ROOT / "tool/generate_release_evidence.rb"
  SHA = "a" * 40

  def test_generates_deterministic_cyclonedx_and_slsa_evidence
    Dir.mktmpdir("saydin-release-evidence-") do |directory|
      directory = Pathname(directory)
      aab = directory / "saydin-v1.2.3.aab"
      ipa = directory / "saydin-v1.2.3.ipa"
      aab.write("android-artifact")
      ipa.write("ios-artifact")
      sbom = directory / "saydin-v1.2.3.cdx.json"
      provenance = directory / "saydin-v1.2.3.provenance.json"

      command = [
        "ruby", SCRIPT.to_s,
        "--repo-root", ROOT.to_s,
        "--release-tag", "v1.2.3",
        "--source-sha", SHA,
        "--build-number", "4201",
        "--timestamp", "2026-08-18T12:00:00Z",
        "--repository", "example/saydin",
        "--run-id", "12345",
        "--artifact", aab.to_s,
        "--artifact", ipa.to_s,
        "--sbom", sbom.to_s,
        "--provenance", provenance.to_s
      ]
      stdout, stderr, status = Open3.capture3(*command)
      assert status.success?, "#{stdout}\n#{stderr}"

      parsed_sbom = JSON.parse(sbom.read)
      assert_equal "CycloneDX", parsed_sbom.fetch("bomFormat")
      assert_equal "1.6", parsed_sbom.fetch("specVersion")
      assert_match(/^urn:uuid:/, parsed_sbom.fetch("serialNumber"))
      assert_equal "1.2.3+4201", parsed_sbom.dig("metadata", "component", "version")
      assert parsed_sbom.fetch("components").any? { |component| component["name"] == "decimal" }
      refs = parsed_sbom.fetch("components").map { |component| component.fetch("bom-ref") }
      assert_equal refs.uniq.sort, refs.sort

      parsed_provenance = JSON.parse(provenance.read)
      assert_equal "https://slsa.dev/provenance/v1", parsed_provenance.fetch("predicateType")
      subjects = parsed_provenance.fetch("subject").to_h { |item| [item.fetch("name"), item] }
      assert_equal Digest::SHA256.file(aab).hexdigest,
                   subjects.fetch(aab.basename.to_s).dig("digest", "sha256")
      assert_equal Digest::SHA256.file(ipa).hexdigest,
                   subjects.fetch(ipa.basename.to_s).dig("digest", "sha256")
      external = parsed_provenance.dig("predicate", "buildDefinition", "externalParameters")
      assert_equal "3.41.4", external.dig("toolchain", "flutter")
      dependencies = parsed_provenance.dig(
        "predicate", "buildDefinition", "resolvedDependencies"
      )
      assert dependencies.any? { |item| item.fetch("uri").end_with?("pubspec.lock") }
    end
  end

  def test_fails_closed_when_artifact_is_missing
    Dir.mktmpdir("saydin-release-evidence-") do |directory|
      directory = Pathname(directory)
      _stdout, stderr, status = Open3.capture3(
        "ruby", SCRIPT.to_s,
        "--repo-root", ROOT.to_s,
        "--release-tag", "v1.2.3",
        "--source-sha", SHA,
        "--build-number", "4201",
        "--timestamp", "2026-08-18T12:00:00Z",
        "--repository", "example/saydin",
        "--run-id", "12345",
        "--artifact", (directory / "missing.aab").to_s,
        "--sbom", (directory / "bom.json").to_s,
        "--provenance", (directory / "provenance.json").to_s
      )
      refute status.success?
      assert_includes stderr, "artifact is missing"
    end
  end
end
