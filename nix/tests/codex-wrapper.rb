#!/usr/bin/env ruby
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

class CodexWrapperTest < Minitest::Test
  WRAPPER = ENV.fetch("CODEX_TEST_WRAPPER") { File.expand_path("../files/bin/codex", __dir__) }

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(["#{@root}/wrapper", "#{@root}/real", "#{@root}/.pi/agent"])
    File.symlink(WRAPPER, "#{@root}/wrapper/codex")
    File.write("#{@root}/real/codex", <<~SH)
      #!#{RbConfig.ruby}
      require "json"
      puts JSON.generate(args: ARGV, token: ENV["CLOUDFLARE_API_KEY"])
    SH
    File.chmod(0o755, "#{@root}/real/codex")
    File.write("#{@root}/.pi/agent/auth.json", JSON.generate("cloudflare-ai-gateway" => {"key" => "test-token"}))
    @env = {"HOME" => @root, "CLOUDFLARE_API_KEY" => nil,
            "PATH" => "#{@root}/wrapper:#{@root}/real:#{ENV.fetch('PATH')}"}
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def launch(*args)
    output, error, status = Open3.capture3(@env, "bash", "#{@root}/wrapper/codex", *args)
    assert status.success?, error
    JSON.parse(output)
  end

  def test_interactive_and_noninteractive_cli_use_profile
    [[], ["hello world"], ["exec", "a prompt with spaces"], ["review", "--uncommitted"],
     ["resume", "--last"], ["fork", "--last"], ["debug", "prompt-input", "hello"],
     ["-C", "app", "exec", "hello"], ["exec", "app"]].each do |args|
      actual = launch(*args)
      assert_equal ["--profile", "cloudflare-cli", *args], actual["args"]
      assert_equal "test-token", actual["token"]
    end
  end

  def test_desktop_account_and_explicit_profile_bypass
    [["app"], ["app-server"], ["-C", "/tmp", "app"], ["remote-control", "status"],
     ["login", "status"], ["logout"], ["cloud"], ["mcp-server"], ["exec-server"],
     ["features", "list"], ["plugin", "list"], ["-C", "/tmp", "plugin", "list"],
     ["completion", "fish"], ["doctor"], ["debug", "models"],
     ["update"], ["apply", "patch"], ["help"], ["--profile", "chatgpt"],
     ["exec", "--profile=chatgpt", "hello"], ["-pchatgpt"], ["--oss"],
     ["--remote", "unix:///tmp/codex"]].each do |args|
      actual = launch(*args)
      assert_equal args, actual["args"]
      assert_nil actual["token"]
    end
  end

  def test_home_manager_symlink_chain_is_skipped_when_finding_real_cli
    store = "#{@root}/store/home-manager-files/bin"
    FileUtils.mkdir_p(store)
    File.symlink(WRAPPER, "#{store}/codex")
    File.unlink("#{@root}/wrapper/codex")
    File.symlink("#{store}/codex", "#{@root}/wrapper/codex")
    @env["PATH"] = "#{@root}/wrapper:#{store}:#{@root}/real:#{ENV.fetch('PATH')}"

    actual = launch("exec", "hello")
    assert_equal ["--profile", "cloudflare-cli", "exec", "hello"], actual["args"]
    assert_equal "test-token", actual["token"]
  end

  def test_existing_token_is_preserved
    @env["CLOUDFLARE_API_KEY"] = "provided-token"
    assert_equal "provided-token", launch("exec", "hello")["token"]
  end

  def test_missing_credentials_does_not_break_help
    File.unlink("#{@root}/.pi/agent/auth.json")
    assert_nil launch("--help")["token"]
  end

  def test_prompt_after_separator_is_not_interpreted_as_a_flag
    args = ["exec", "--", "--profile=not-a-profile"]
    assert_equal ["--profile", "cloudflare-cli", *args], launch(*args)["args"]
  end
end
