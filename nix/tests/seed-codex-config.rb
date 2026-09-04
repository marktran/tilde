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
  STARTER = <<~TOML
    model = "starter"
    model_provider = "cloudflare-ai-gateway"
    [model_providers.cloudflare-ai-gateway]
    base_url = "https://gateway.example/openai"
    env_key = "CLOUDFLARE_API_KEY"
  TOML
  LOCAL = STARTER.sub('"starter"', '"local"') + <<~TOML

    # Preserve local trust and plugin choices.
    [projects."/local"]
    trust_level = "trusted"
    [plugins.example]
    enabled = true
  TOML
  PROFILE = <<~TOML
    model = "gpt-5.6-sol"
    model_reasoning_effort = "high"
    model_provider = "openai"
  TOML

  def setup
    @root = Dir.mktmpdir
    @defaults = File.join(@root, "defaults")
    @settings = File.join(@root, ".codex")
    FileUtils.mkdir_p([@defaults, @settings])
    File.write(File.join(@defaults, "config.toml"), STARTER)
    @config = File.join(@settings, "config.toml")
    @profile = File.join(@settings, "chatgpt.config.toml")
    @backups = File.join(@settings, "backups")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def run_helper(success: true)
    output, error, status = Open3.capture3(*HELPER, @defaults, @settings)
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

  def test_seed_single_config_and_preserve_existing
    Dir.rmdir(@settings)
    run_helper
    assert_equal STARTER, File.read(@config)
    refute File.symlink?(@config)
    assert_equal 0o600, File.stat(@config).mode & 0o777
    refute File.exist?(@profile)
    File.write(@config, LOCAL)
    File.chmod(0o400, @config)
    before = File.stat(@config)
    run_helper
    assert_equal LOCAL, File.read(@config)
    after = File.stat(@config)
    %i[mode ino mtime].each { |field| assert_equal before.public_send(field), after.public_send(field) }
  end

  def test_detach_legacy_main_links
    source = File.join(@root, "store.toml")
    intermediate = File.join(@root, "intermediate")
    File.write(source, LOCAL)
    File.chmod(0o444, source)
    File.symlink(source, intermediate)
    File.symlink(intermediate, @config)
    run_helper
    refute File.symlink?(@config)
    assert_equal LOCAL, File.read(@config)
    assert_equal 0o600, File.stat(@config).mode & 0o777
    assert_equal LOCAL, File.read(source)
  end

  def test_profile_migration_and_idempotence
    File.write(@config, LOCAL)
    File.write(@profile, PROFILE)
    run_helper
    expected = parse(LOCAL).merge("model" => "gpt-5.6-sol", "model_reasoning_effort" => "high")
    assert_equal expected, parse(File.read(@config))
    assert_includes File.read(@config), "# Preserve local trust"
    refute File.exist?(@profile)
    backups = Dir.children(@backups)
    assert_equal 1, backups.size
    backup = File.join(@backups, backups.first)
    assert_equal LOCAL, File.read(File.join(backup, "config.toml"))
    assert_equal PROFILE, File.read(File.join(backup, "chatgpt.config.toml"))
    assert_equal 0o700, File.stat(backup).mode & 0o777
    assert_equal 0o600, File.stat(File.join(backup, "config.toml")).mode & 0o777
    # Later local choices must not be reset by another switch.
    contents = File.read(@config).sub('"gpt-5.6-sol"', '"later"')
    File.write(@config, contents)
    run_helper
    assert_equal contents, File.read(@config)
    assert_equal backups, Dir.children(@backups)
  end

  def test_migrate_linked_profile_with_missing_main
    source = File.join(@root, "profile.toml")
    File.write(source, PROFILE)
    File.chmod(0o444, source)
    File.symlink(source, @profile)
    run_helper
    assert_equal PROFILE, File.read(source)
    refute File.symlink?(@profile)
    config = parse(File.read(@config))
    assert_equal "cloudflare-ai-gateway", config["model_provider"]
    assert_equal "gpt-5.6-sol", config["model"]
  end

  def test_add_missing_gateway_definition_during_migration
    File.write(@config, "model_provider = \"openai\"\n")
    File.write(@profile, PROFILE)
    run_helper
    config = parse(File.read(@config))
    assert_equal "cloudflare-ai-gateway", config["model_provider"]
    assert_equal parse(STARTER)["model_providers"], config["model_providers"]
  end

  def test_preserve_multiline_strings_quoted_keys_and_comments
    contents = <<~'TOML'
      # My café preferences.
      'model' = 'old-model' # Keep this note.
      model_provider = 'openai'
      notes = """
      model = "not-a-setting"
      [not_a_table]
      """
      [plugins."example.with.dots"]
      enabled = false # Keep this too.
    TOML
    File.write(@config, contents)
    File.write(@profile, PROFILE)
    run_helper
    actual = File.read(@config, encoding: Encoding::UTF_8)
    expected = parse(contents).merge(parse(PROFILE))
    expected["model_provider"] = "cloudflare-ai-gateway"
    expected["model_providers"] = parse(STARTER)["model_providers"]
    assert_equal expected, parse(actual)
    ["# My café preferences.", "# Keep this note.", "# Keep this too."].each do |comment|
      assert_includes actual, comment
    end
  end

  def test_invalid_paths_or_profile_leave_main_untouched
    File.write(@config, LOCAL)
    %i[broken directory invalid_toml].each do |bad_profile|
      case bad_profile
      when :broken then File.symlink(File.join(@root, "missing"), @profile)
      when :directory then Dir.mkdir(@profile)
      else File.write(@profile, "not valid toml [")
      end
      run_helper(success: false)
      assert_equal LOCAL, File.read(@config)
      refute File.exist?(@backups)
      File.directory?(@profile) ? Dir.rmdir(@profile) : File.unlink(@profile)
    end
    File.unlink(@config)
    File.symlink(File.join(@root, "missing"), @config)
    run_helper(success: false)
    assert File.symlink?(@config)
  end
end
