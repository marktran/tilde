require "minitest/autorun"
require "fileutils"
require "stringio"
require "tmpdir"
require_relative "reap-stale-services"

class StaleWorktreeServicesTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir
    @home = File.join(@root, "home")
    @worktrees = File.join(@home, ".herdr/worktrees/museum")
    @signals = []
    @output = StringIO.new
    @reaper = StaleWorktreeServices.new(home: @home, proc_root: @root,
      signaler: ->(pid) { @signals << pid }, output: @output)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_stops_deleted_worktree_supervisors_and_postgres
    process(101, "process-compose", "#{@worktrees}/old (deleted)")
    process(102, "postgres", "#{@worktrees}/old/.devbox/virtenv/postgresql_18/data (deleted)")
    @reaper.run
    assert_equal [101, 102], @signals
  end

  def test_preserves_main_checkout_live_worktrees_and_unrelated_processes
    process(101, "process-compose", "#{@home}/src/vhm/museum (deleted)")
    process(102, "process-compose", "#{@worktrees}/live")
    process(103, "bash", "#{@worktrees}/old (deleted)")
    process(104, "process-compose", "#{@worktrees}-other/old (deleted)")
    @reaper.run
    assert_empty @signals
  end

  def test_dry_run_reports_without_signalling
    process(101, "process-compose", "#{@worktrees}/old (deleted)")
    @reaper.run(dry_run: true)
    assert_empty @signals
    assert_includes @output.string, "Would stop 101"
  end

  def test_ignores_other_users
    process(101, "process-compose", "#{@worktrees}/old (deleted)")
    reaper = StaleWorktreeServices.new(home: @home, proc_root: @root, uid: Process.uid + 1,
      signaler: ->(pid) { @signals << pid })
    reaper.run
    assert_empty @signals
  end

  def test_ignores_exiting_processes
    process(101, "process-compose", "#{@worktrees}/old (deleted)")
    File.unlink(File.join(@root, "101/stat"))
    @reaper.run
    assert_empty @signals
  end

  def test_checks_identity_again_before_signalling
    process(101, "process-compose", "#{@worktrees}/old (deleted)")
    calls = 0
    @reaper.define_singleton_method(:stale_identity) do |directory|
      identity = super(directory)
      calls += 1
      identity[2] = "new-start-time" if calls == 2
      identity
    end
    @reaper.run
    assert_empty @signals
  end

  private

  def process(pid, name, cwd)
    directory = File.join(@root, pid.to_s)
    FileUtils.mkdir_p(directory)
    File.symlink("/nix/store/test/bin/#{name}", File.join(directory, "exe"))
    File.symlink(cwd, File.join(directory, "cwd"))
    File.write(File.join(directory, "stat"), "#{pid} (#{name}) S #{(['0'] * 18).join(' ')} 12345 0\n")
  end
end
