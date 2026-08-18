#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "digest"
require "json"
require "optparse"
require "pathname"
require "yaml"

options = { artifacts: [] }
OptionParser.new do |parser|
  parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
  parser.on("--release-tag TAG") { |value| options[:release_tag] = value }
  parser.on("--source-sha SHA") { |value| options[:source_sha] = value }
  parser.on("--build-number NUMBER") { |value| options[:build_number] = value }
  parser.on("--timestamp ISO8601") { |value| options[:timestamp] = value }
  parser.on("--repository OWNER/REPO") { |value| options[:repository] = value }
  parser.on("--run-id ID") { |value| options[:run_id] = value }
  parser.on("--artifact PATH") { |value| options[:artifacts] << value }
  parser.on("--sbom PATH") { |value| options[:sbom] = value }
  parser.on("--provenance PATH") { |value| options[:provenance] = value }
end.parse!

required = %i[
  repo_root release_tag source_sha build_number timestamp repository run_id sbom provenance
]
missing = required.select { |key| options[key].to_s.empty? }
abort "Missing required options: #{missing.join(', ')}" unless missing.empty?
abort "At least one --artifact is required" if options[:artifacts].empty?
abort "source SHA must be 40 lowercase hex characters" unless options[:source_sha].match?(/\A[0-9a-f]{40}\z/)

root = Pathname(options[:repo_root]).expand_path
lock_path = root / "pubspec.lock"
pubspec_path = root / "pubspec.yaml"
abort "pubspec.lock is missing" unless lock_path.file?
abort "pubspec.yaml is missing" unless pubspec_path.file?

pubspec = YAML.safe_load(pubspec_path.read, permitted_classes: [], aliases: false)
lock = YAML.safe_load(lock_path.read, permitted_classes: [], aliases: false)
packages = lock.fetch("packages")
source_package_version = pubspec.fetch("version")
environment = pubspec.fetch("environment")
flutter_version = environment.fetch("flutter")
dart_constraint = environment.fetch("sdk")
release_version = options[:release_tag].delete_prefix("v").sub(/-rc\.\d+\z/, "")
artifact_version = "#{release_version}+#{options[:build_number]}"

escape = ->(value) { CGI.escape(value.to_s).gsub("+", "%20") }
components = packages.sort.map do |name, package|
  version = package.fetch("version")
  source = package.fetch("source")
  description = package["description"]
  hosted = source == "hosted" && description.is_a?(Hash)
  bom_ref = if hosted
              "pkg:pub/#{escape.call(name)}@#{escape.call(version)}"
            else
              "pkg:generic/dart/#{escape.call(name)}@#{escape.call(version)}?source=#{escape.call(source)}"
            end
  component = {
    "type" => "library",
    "bom-ref" => bom_ref,
    "name" => name,
    "version" => version,
    "purl" => bom_ref,
    "properties" => [
      { "name" => "saydin:dependency-scope", "value" => package.fetch("dependency").to_s },
      { "name" => "saydin:package-source", "value" => source.to_s }
    ]
  }
  sha256 = description["sha256"] if hosted
  component["hashes"] = [{ "alg" => "SHA-256", "content" => sha256 }] if sha256
  component
end

serial_hex = Digest::SHA256.hexdigest(
  "#{options[:source_sha]}:#{options[:release_tag]}:#{options[:build_number]}"
)[0, 32]
serial_hex[12] = "5"
serial_hex[16] = ((serial_hex[16].to_i(16) & 0x3) | 0x8).to_s(16)
serial_uuid = [8, 4, 4, 4, 12].map { |length| serial_hex.slice!(0, length) }.join("-")
root_ref = "pkg:generic/saydin@#{escape.call(artifact_version)}"

sbom = {
  "bomFormat" => "CycloneDX",
  "specVersion" => "1.6",
  "serialNumber" => "urn:uuid:#{serial_uuid}",
  "version" => 1,
  "metadata" => {
    "timestamp" => options[:timestamp],
    "component" => {
      "type" => "application",
      "bom-ref" => root_ref,
      "name" => "saydin",
      "version" => artifact_version,
      "properties" => [
        { "name" => "saydin:release-tag", "value" => options[:release_tag] },
        { "name" => "saydin:source-sha", "value" => options[:source_sha] },
        { "name" => "saydin:build-number", "value" => options[:build_number] },
        { "name" => "saydin:source-package-version", "value" => source_package_version },
        { "name" => "saydin:flutter-version", "value" => flutter_version },
        { "name" => "saydin:dart-constraint", "value" => dart_constraint },
        { "name" => "saydin:sbom-scope", "value" => "pubspec.lock" }
      ]
    }
  },
  "components" => components,
  "dependencies" => [
    { "ref" => root_ref, "dependsOn" => components.map { |component| component.fetch("bom-ref") } }
  ]
}

subjects = options[:artifacts].sort.map do |artifact_path|
  artifact = Pathname(artifact_path).expand_path
  abort "artifact is missing: #{artifact}" unless artifact.file?
  {
    "name" => artifact.basename.to_s,
    "digest" => { "sha256" => Digest::SHA256.file(artifact).hexdigest }
  }
end

repository_uri = "git+https://github.com/#{options[:repository]}@#{options[:source_sha]}"
dependency_manifests = [
  "pubspec.lock",
  "ios/Podfile.lock",
  "android/settings.gradle.kts",
  "android/app/build.gradle.kts",
  "android/gradle/wrapper/gradle-wrapper.properties"
].each_with_object([]) do |relative_path, manifests|
  path = root / relative_path
  next unless path.file?

  manifests << {
    "uri" => "pkg:generic/saydin/#{relative_path}",
    "digest" => { "sha256" => Digest::SHA256.file(path).hexdigest }
  }
end
provenance = {
  "_type" => "https://in-toto.io/Statement/v1",
  "subject" => subjects,
  "predicateType" => "https://slsa.dev/provenance/v1",
  "predicate" => {
    "buildDefinition" => {
      "buildType" => "https://github.com/#{options[:repository]}/.github/workflows/release.yml@v1",
      "externalParameters" => {
        "releaseTag" => options[:release_tag],
        "buildNumber" => options[:build_number],
        "toolchain" => {
          "flutter" => flutter_version,
          "dartConstraint" => dart_constraint
        },
        "targetRunners" => ["ubuntu-latest", "macos-15"]
      },
      "resolvedDependencies" => [
        { "uri" => repository_uri, "digest" => { "gitCommit" => options[:source_sha] } },
        *dependency_manifests
      ]
    },
    "runDetails" => {
      "builder" => {
        "id" => "https://github.com/#{options[:repository]}/actions/runs/#{options[:run_id]}"
      },
      "metadata" => { "invocationId" => options[:run_id] }
    }
  }
}

{ options[:sbom] => sbom, options[:provenance] => provenance }.each do |path, document|
  output = Pathname(path)
  output.dirname.mkpath
  output.write(JSON.pretty_generate(document) + "\n")
end
