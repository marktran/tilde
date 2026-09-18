#!/usr/bin/env ruby
# Seed local Codex configs; move the global gateway default into a CLI profile.

require "fileutils"
require "json"
require "open3"
require "tempfile"
require "tmpdir"

module CodexConfig
  GATEWAY = "cloudflare-ai-gateway"

  module_function

  def atomic_write(path, contents)
    # Replace the file/link itself with a private, writable regular file.
    Tempfile.create(["#{File.basename(path)}.tmp.", ""], File.dirname(path)) do |file|
      file.binmode
      file.write(contents)
      file.flush
      File.rename(file.path, path)
    end
  end

  def read_existing(path)
    return unless File.exist?(path) || File.symlink?(path)

    # Never silently reset a broken link, directory, or unreadable config.
    raise "Not a regular file or readable file link: #{path}" unless File.file?(path)

    File.binread(path)
  end

  def toml(command, contents, *arguments)
    # toml-cli uses toml_edit to preserve unrelated formatting and comments.
    # Work on private snapshots, not the live file, until every edit validates.
    Tempfile.create(["codex-config-", ".toml"]) do |file|
      file.binmode
      file.write(contents)
      file.flush
      output, error, status = Open3.capture3("toml", command, file.path, *arguments)
      raise "toml #{command} failed: #{error.strip}" unless status.success?

      output.force_encoding(Encoding::UTF_8)
    end
  end

  def parse(contents)
    JSON.parse(toml("get", contents, "."))
  end

  def set_string(contents, key, value, existing:)
    original = existing ? toml("get", contents, key, "--output-toml") : ""
    # toml-cli 0.2.3 drops the replaced value's trailing comment. Recover it
    # from the parser-selected entry, not a scan through arbitrary TOML text.
    comment = original[/['"]([ \t]*#[^\r\n]*)\r?\n?\z/, 1]
    updated = toml("set", contents, key, value)
    return updated unless comment

    entry = toml("get", updated, key, "--output-toml")
    literal = entry.split("=", 2).last.strip
    assignment = /^([ \t]*(?:#{key}|"#{key}"|'#{key}')[ \t]*=[ \t]*#{Regexp.escape(literal)})[ \t]*(\r?)$/
    # Reject ambiguity rather than touch a lookalike inside a multiline string.
    raise "Cannot safely preserve the comment for #{key}" unless updated.scan(assignment).size == 1

    updated.sub(assignment) { "#{Regexp.last_match(1)}#{comment}#{Regexp.last_match(2)}" }
  end

  def cli_profile(defaults, base, base_contents)
    contents = File.binread(File.join(defaults, "cloudflare-cli.config.toml"))
    # Preserve the existing CLI model and provider definition during migration.
    return contents unless base["model_provider"] == GATEWAY

    base.slice("model", "model_reasoning_effort").each do |key, value|
      raise "Expected a string for #{key}" unless value.is_a?(String)

      contents = set_string(contents, key, value, existing: parse(contents).key?(key))
    end
    if base.fetch("model_providers", {}).key?(GATEWAY)
      entries = %w[model model_reasoning_effort model_provider].map do |key|
        toml("get", contents, key, "--output-toml")
      end
      entries << toml("get", base_contents, "model_providers.#{GATEWAY}", "--output-toml")
      contents = "# CLI-only gateway profile, selected by ~/bin/codex.\n" + entries.join("\n")
    end
    contents
  end

  def seed(defaults, settings)
    target = File.join(settings, "config.toml")
    profile = File.join(settings, "cloudflare-cli.config.toml")
    original = read_existing(target)
    original_profile = read_existing(profile)
    contents = original || File.binread(File.join(defaults, "config.toml"))
    base = parse(contents)
    profile_contents = original_profile || cli_profile(defaults, base, contents)
    parse(profile_contents) # Validate both files before making any changes.

    migrating = base["model_provider"] == GATEWAY
    if migrating
      contents = set_string(contents, "model_provider", "openai", existing: true)
      raise "Migration changed unrelated Codex settings" unless parse(contents) == base.merge("model_provider" => "openai")
    end

    FileUtils.mkdir_p(settings)
    if migrating
      backups = File.join(settings, "backups")
      FileUtils.mkdir_p(backups, mode: 0o700)
      backup = Dir.mktmpdir("cli-only-gateway-", backups)
      atomic_write(File.join(backup, "config.toml"), original) if original
      atomic_write(File.join(backup, "cloudflare-cli.config.toml"), original_profile) if original_profile
      puts "Separating Codex CLI routing from Desktop; originals: #{backup}"
    end
    # Write the profile first so a failed write cannot discard CLI choices.
    # Preserve existing regular files; detach links before HM orphan cleanup.
    if original_profile.nil? || File.symlink?(profile)
      atomic_write(profile, profile_contents)
      puts "Initialized CLI-only Codex profile: #{profile}"
    end
    if migrating || original.nil? || File.symlink?(target)
      atomic_write(target, contents)
      puts "Initialized app-owned Codex config: #{target}"
    end
    # Legacy chatgpt.config.toml and auth.json are deliberately left untouched.
  end
end

CodexConfig.seed(*ARGV) if $PROGRAM_NAME == __FILE__
