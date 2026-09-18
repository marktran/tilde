#!/usr/bin/env ruby
# Runs during the Nix helper build; direct runs need Ruby, Minitest, and toml-cli.

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tempfile"
require "tmpdir"

HELPER = if ARGV.empty?
  [RbConfig.ruby, File.expand_path("../home-manager/common/seed-codex-config.rb", __dir__)]
else
  [ARGV.shift]
end

class SeedCodexConfigTest < Minitest::Test
  DEFAULTS = ENV.fetch("CODEX_TEST_DEFAULTS") { File.expand_path("../files/codex", __dir__) }
  STARTER = File.read(File.join(DEFAULTS, "config.toml"))
  PROFILE = File.read(File.join(DEFAULTS, "cloudflare-cli.config.toml"))
  LOCAL = STARTER + <<~TOML

    # Preserve local trust and plugin choices.
    [projects."/local"]
    trust_level = "trusted"
    [plugins.example]
    enabled = true
  TOML
  GATEWAY = <<~TOML
    # My café preferences.
    'model' = 'local-model' # Keep this note.
    model_reasoning_effort = "high"
    model_provider = 'cloudflare-ai-gateway' # Keep routing note.
    notes = """
    model_provider = "not-a-setting"
    [not_a_table]
    """
    [model_providers.cloudflare-ai-gateway]
    base_url = "https://custom.example/openai"
    env_key = "CUSTOM_TOKEN"
    wire_api = "responses"
    [plugins."example.with.dots"]
    enabled = false # Keep this too.
  TOML

  def setup
    @root = Dir.mktmpdir
    @settings = File.join(@root, ".codex")
    FileUtils.mkdir_p(@settings)
    @config = File.join(@settings, "config.toml")
    @profile = File.join(@settings, "cloudflare-cli.config.toml")
    @backups = File.join(@settings, "backups")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def run_helper(success: true)
    output, error, status = Open3.capture3(*HELPER, DEFAULTS, @settings)
    assert_equal success, status.success?, "#{output}\n#{error}"
  end

  def parse(contents)
    Tempfile.create(["codex-test-", ".toml"]) do |file|
      file.write(contents)
      file.flush
      output, error, status = Open3.capture3("toml", "get", file.path, ".")
      assert status.success?, error
      JSON.parse(output)
    end
  end

  def test_seed_desktop_base_and_cli_profile
    Dir.rmdir(@settings)
    run_helper
    assert_equal STARTER, File.read(@config)
    assert_equal PROFILE, File.read(@profile)
    assert_equal "openai", parse(File.read(@config))["model_provider"]
    assert_equal "cloudflare-ai-gateway", parse(File.read(@profile))["model_provider"]
    [@config, @profile].each do |path|
      refute File.symlink?(path)
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
    refute File.exist?(@backups)
  end

  def test_preserve_existing_regular_files_and_legacy_chatgpt_profile
    File.write(@config, LOCAL)
    File.write(@profile, PROFILE.sub('"low"', '"medium"'))
    legacy = File.join(@settings, "chatgpt.config.toml")
    File.write(legacy, 'model_provider = "openai"')
    [@config, @profile, legacy].each { |path| File.chmod(0o400, path) }
    before = [@config, @profile, legacy].map { |path| [File.read(path), File.stat(path)] }
    run_helper
    [@config, @profile, legacy].zip(before).each do |path, (contents, stat)|
      assert_equal contents, File.read(path)
      %i[mode ino mtime].each { |field| assert_equal stat.public_send(field), File.stat(path).public_send(field) }
    end
    refute File.exist?(@backups)
  end

  def test_detach_legacy_links_without_mutating_source
    [@config, @profile].zip([LOCAL, PROFILE]).each_with_index do |(path, contents), index|
      source = File.join(@root, "store-#{index}.toml")
      File.write(source, contents)
      File.chmod(0o444, source)
      File.symlink(source, path)
    end
    run_helper
    [@config, @profile].zip([LOCAL, PROFILE]).each_with_index do |(path, contents), index|
      refute File.symlink?(path)
      assert_equal contents, File.read(path)
      assert_equal contents, File.read(File.join(@root, "store-#{index}.toml"))
      assert_equal 0o600, File.stat(path).mode & 0o777
    end
  end

  def test_gateway_migration_preserves_settings_and_is_idempotent
    File.write(@config, GATEWAY)
    run_helper
    actual = File.read(@config, encoding: Encoding::UTF_8)
    assert_equal parse(GATEWAY).merge("model_provider" => "openai"), parse(actual)
    ["# My café preferences.", "# Keep this note.", "# Keep routing note.", "# Keep this too."].each do |comment|
      assert_includes actual, comment
    end
    profile = parse(File.read(@profile))
    assert_equal "cloudflare-ai-gateway", profile["model_provider"]
    assert_equal "local-model", profile["model"]
    assert_equal "high", profile["model_reasoning_effort"]
    assert_equal parse(GATEWAY)["model_providers"], profile["model_providers"]
    backups = Dir.children(@backups)
    assert_equal 1, backups.size
    backup = File.join(@backups, backups.first)
    assert_equal GATEWAY.b, File.binread(File.join(backup, "config.toml"))
    assert_equal 0o700, File.stat(backup).mode & 0o777
    assert_equal 0o600, File.stat(File.join(backup, "config.toml")).mode & 0o777
    File.write(@config, actual.sub("local-model", "desktop-choice"))
    contents = File.read(@config)
    run_helper
    assert_equal contents, File.read(@config)
    assert_equal profile, parse(File.read(@profile))
    assert_equal backups, Dir.children(@backups)
  end

  def test_migrate_legacy_linux_gateway_link_without_changing_checkout
    contents = GATEWAY + <<~TOML
      [projects."/home/mark/src/mark/tilde"]
      trust_level = "trusted"
    TOML
    source = File.join(@root, "checkout-config.toml")
    intermediate = File.join(@root, "home-manager-link")
    File.write(source, contents)
    File.symlink(source, intermediate)
    File.symlink(intermediate, @config)

    run_helper

    refute File.symlink?(@config)
    assert_equal 0o600, File.stat(@config).mode & 0o777
    assert_equal contents.b, File.binread(source)
    assert_equal parse(contents).merge("model_provider" => "openai"), parse(File.read(@config))
    profile = parse(File.read(@profile))
    assert_equal "cloudflare-ai-gateway", profile["model_provider"]
    assert_equal "local-model", profile["model"]
    assert_equal "high", profile["model_reasoning_effort"]
    assert_equal parse(contents)["model_providers"], profile["model_providers"]
    backup = Dir.glob(File.join(@backups, "*", "config.toml")).fetch(0)
    assert_equal contents.b, File.binread(backup)
  end

  def test_migration_preserves_existing_cli_profile
    File.write(@config, GATEWAY)
    File.write(@profile, PROFILE)
    run_helper
    assert_equal PROFILE, File.read(@profile)
    backup = Dir.glob(File.join(@backups, "*", "cloudflare-cli.config.toml")).fetch(0)
    assert_equal PROFILE, File.read(backup)
  end

  def test_gateway_without_provider_definition_gets_starter_definition
    File.write(@config, "model_provider = \"cloudflare-ai-gateway\"\n")
    run_helper
    assert_equal PROFILE, File.read(@profile)
    assert_equal "openai", parse(File.read(@config))["model_provider"]
  end

  def test_custom_non_gateway_provider_is_untouched
    contents = LOCAL.sub('"openai"', '"custom"')
    File.write(@config, contents)
    run_helper
    assert_equal contents, File.read(@config)
    refute File.exist?(@backups)
  end

  def test_invalid_inputs_fail_before_any_changes
    [@config, @profile].each do |bad_path|
      %i[broken directory invalid_toml].each do |kind|
        File.write(@config, GATEWAY)
        File.write(@profile, PROFILE)
        File.unlink(bad_path)
        case kind
        when :broken then File.symlink(File.join(@root, "missing"), bad_path)
        when :directory then Dir.mkdir(bad_path)
        else File.write(bad_path, "not valid toml [")
        end
        other = bad_path == @config ? @profile : @config
        contents = File.read(other)
        run_helper(success: false)
        assert_equal contents, File.read(other)
        refute File.exist?(@backups)
        File.directory?(bad_path) ? Dir.rmdir(bad_path) : File.unlink(bad_path)
      end
    end
  end
end
