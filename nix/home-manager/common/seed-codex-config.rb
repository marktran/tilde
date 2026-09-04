#!/usr/bin/env ruby
# Seed a local Codex config; migrate the retired ChatGPT profile once.

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

  def migrate(contents, profile, starter)
    expected = parse(contents)
    overrides = parse(profile)
    changes = overrides.slice("model", "model_reasoning_effort")
    changes["model_provider"] = GATEWAY
    changes.each do |key, value|
      raise "Expected a string for #{key}" unless value.is_a?(String)

      contents = set_string(contents, key, value, existing: expected.key?(key))
      expected[key] = value
    end
    providers = expected["model_providers"] ||= {}
    unless providers.key?(GATEWAY)
      defaults = File.binread(starter)
      providers[GATEWAY] = parse(defaults).fetch("model_providers").fetch(GATEWAY)
      contents += "\n" + toml("get", defaults, "model_providers.#{GATEWAY}", "--output-toml")
    end
    raise "Migration changed unrelated Codex settings" unless parse(contents) == expected

    # Retire the old repo-generated comments as well as the profile.
    legacy_header = <<~TEXT
      # Codex CLI user config, repo-managed as a writable out-of-store link
      # (see nix/home-manager/common/agents.nix): codex itself rewrites this file
      # (project trust, TUI state, notices), so runtime writes land in the checkout
      # and show up as ordinary git drift.
    TEXT
    legacy_profile_note = <<~TEXT
      # Interactive ChatGPT-auth usage: `codex --profile chatgpt` (fish abbr:
      # codex), which layers chatgpt.config.toml on top of this file.
    TEXT
    contents.sub(legacy_header, "# Codex-owned local config. Settings changes stay local, not in Git.\n")
            .sub(legacy_profile_note, "# Interactive and non-interactive Codex both use Cloudflare AI Gateway.\n")
  end

  def seed(defaults, settings)
    target = File.join(settings, "config.toml")
    profile = File.join(settings, "chatgpt.config.toml")
    original = read_existing(target)
    profile_contents = read_existing(profile)
    starter = File.join(defaults, "config.toml")
    contents = original || File.binread(starter)

    if profile_contents
      contents = migrate(contents, profile_contents, starter)
      # Snapshot resolved contents, not links into a mutable checkout or old
      # Nix generation. Keep both originals before changing either live file.
      backups = File.join(settings, "backups")
      FileUtils.mkdir_p(backups, mode: 0o700)
      backup = Dir.mktmpdir("gateway-migration-", backups)
      atomic_write(File.join(backup, "config.toml"), original) if original
      atomic_write(File.join(backup, "chatgpt.config.toml"), profile_contents)
      atomic_write(target, contents)
      File.unlink(profile)
      puts "Migrated Codex to Cloudflare AI Gateway; originals: #{backup}"
    elsif original.nil? || File.symlink?(target)
      # Seed only if missing; detach legacy main-config links before HM's
      # orphan cleanup. Existing regular files stay completely untouched.
      FileUtils.mkdir_p(settings)
      atomic_write(target, contents)
      puts "Initialized app-owned Codex config: #{target}"
    end
  end
end

CodexConfig.seed(*ARGV) if $PROGRAM_NAME == __FILE__
