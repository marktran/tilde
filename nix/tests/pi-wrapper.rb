#!/usr/bin/env ruby
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class PiWrapperTest < Minitest::Test
  WRAPPER = File.expand_path("../files/fish/functions/pi.fish", __dir__)

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(["#{@root}/bin", "#{@root}/.pi/agent", "#{@root}/enterprise/configs"])
    @profile = "#{@root}/enterprise/configs/default.json"
    File.write(@profile, '{"authentication":{"type":"user_oauth"}}')
    File.write("#{@root}/.pi/agent/auth.json", JSON.generate("cloudflare-ai-gateway" => {"key" => "test-token"}))
    File.write("#{@root}/bin/pi", <<~RUBY)
      #!#{RbConfig.ruby}
      require "json"
      dir = ENV["ANTHROPIC_CONFIG_DIR"]
      puts JSON.generate(args: ARGV, dir: dir,
                         entries: dir && Dir.exist?(dir) ? Dir.children(dir) : nil,
                         mode: dir && Dir.exist?(dir) ? File.stat(dir).mode & 0o777 : nil,
                         base_url: ENV["ANTHROPIC_BASE_URL"],
                         api_key: ENV["ANTHROPIC_API_KEY"],
                         headers: ENV["ANTHROPIC_CUSTOM_HEADERS"])
      exit Integer(ENV.fetch("TEST_PI_STATUS", "0"))
    RUBY
    File.chmod(0o755, "#{@root}/bin/pi")
    @env = {"HOME" => @root, "XDG_CONFIG_HOME" => "#{@root}/.config",
            "PATH" => "#{@root}/bin:#{ENV.fetch('PATH')}", "CLOUDFLARE_API_KEY" => nil,
            "ANTHROPIC_CONFIG_DIR" => "#{@root}/enterprise", "ANTHROPIC_BASE_URL" => nil,
            "ANTHROPIC_API_KEY" => nil, "ANTHROPIC_CUSTOM_HEADERS" => nil,
            "TEST_PI_STATUS" => nil}
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def launch(*args, status: 0)
    output, error, result = Open3.capture3(@env, "fish", "--no-config", "-c", <<~FISH, WRAPPER, *args)
      source $argv[1]
      pi $argv[2..]
      set -l result $status
      command pi --probe-parent
      exit $result
    FISH
    assert_equal status, result.exitstatus, error
    output.lines.map { |line| JSON.parse(line) }
  end

  def test_gateway_uses_private_empty_directory_and_preserves_arguments
    actual, parent = launch("--model", "claude-fable-5-1", "a prompt with spaces")
    assert_equal ["--model", "claude-fable-5-1", "a prompt with spaces"], actual["args"]
    refute_equal "#{@root}/enterprise", actual["dir"]
    assert_equal [], actual["entries"]
    assert_equal 0o700, actual["mode"]
    refute File.exist?(actual["dir"]), "Temporary config should be removed after Pi exits"
    assert_equal "#{@root}/enterprise", parent["dir"]
    assert_nil parent["base_url"]
    assert_nil parent["api_key"]
    assert_nil parent["headers"]
    assert_equal '{"authentication":{"type":"user_oauth"}}', File.read(@profile)
    assert_equal "test-token", actual["api_key"]
    assert_equal "cf-aig-authorization: Bearer test-token", actual["headers"]
    assert_match %r{\Ahttps://gateway\.ai\.cloudflare\.com/.+/anthropic\z}, actual["base_url"]
  end

  def test_explicit_gateway_token_takes_precedence
    @env["CLOUDFLARE_API_KEY"] = "provided-token"
    actual, = launch
    assert_equal "provided-token", actual["api_key"]
    assert_equal "cf-aig-authorization: Bearer provided-token", actual["headers"]
    assert_equal [], actual["entries"]
  end

  def test_non_gateway_launch_preserves_enterprise_profile
    File.unlink("#{@root}/.pi/agent/auth.json")
    actual, = launch("--help")
    assert_equal "#{@root}/enterprise", actual["dir"]
    assert_nil actual["base_url"]
    assert_nil actual["api_key"]
    assert File.exist?(@profile)
  end

  def test_missing_profile_override_does_not_leak_into_parent
    @env["ANTHROPIC_CONFIG_DIR"] = nil
    actual, parent = launch
    assert_equal [], actual["entries"]
    assert_nil parent["dir"]
  end

  def test_failure_status_is_preserved_and_directory_is_removed
    @env["TEST_PI_STATUS"] = "42"
    actual, = launch(status: 42)
    refute File.exist?(actual["dir"])
    assert File.exist?(@profile)
  end

  def test_temp_directory_failure_does_not_launch_pi_with_enterprise_profile
    File.write("#{@root}/bin/mktemp", "#!/bin/sh\nexit 73\n")
    File.chmod(0o755, "#{@root}/bin/mktemp")
    results = launch(status: 73)
    assert_equal 1, results.length
    assert_equal ["--probe-parent"], results.first["args"]
  end
end
