#!/usr/bin/env ruby
# Stop only this user's Devbox processes rooted in deleted Museum worktrees.
# Run after deletion as a fallback; normal teardown belongs in Museum itself.
class StaleWorktreeServices
  def initialize(home: Dir.home, proc_root: "/proc", uid: Process.uid,
    signaler: ->(pid) { Process.kill("TERM", pid) }, output: $stdout)
    @worktrees = File.join(home, ".herdr/worktrees/museum") + "/"
    @proc_root = proc_root
    @uid = uid
    @signaler = signaler
    @output = output
  end

  def run(dry_run: false)
    Dir.glob(File.join(@proc_root, "[0-9]*")).sort.each do |directory|
      identity = stale_identity(directory)
      next unless identity
      # Check start time as well as cwd/executable again to reject PID reuse.
      next unless identity == stale_identity(directory)

      pid = Integer(File.basename(directory))
      @signaler.call(pid) unless dry_run
      @output.puts "#{dry_run ? 'Would stop' : 'Sent TERM to'} #{pid}: #{identity[1]}"
    rescue Errno::ESRCH
      # Process exited between inspection and signalling.
    end
  end

  private

  def stale_identity(directory)
    return unless File.stat(directory).uid == @uid

    executable = File.readlink(File.join(directory, "exe"))
    return unless %w[process-compose postgres].include?(File.basename(executable))

    cwd = File.readlink(File.join(directory, "cwd"))
    return unless cwd.start_with?(@worktrees) && cwd.end_with?(" (deleted)")

    # /proc/PID/stat's comm field can contain spaces and parentheses. Field
    # 22 (starttime) is index 19 after the final closing parenthesis.
    start_time = File.read(File.join(directory, "stat")).rpartition(") ").last.split.fetch(19)
    [executable, cwd, start_time]
  rescue Errno::ENOENT, Errno::ESRCH, Errno::EACCES
    nil
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Usage: #{$PROGRAM_NAME} [--dry-run]" unless ARGV.empty? || ARGV == ["--dry-run"]
  StaleWorktreeServices.new.run(dry_run: ARGV == ["--dry-run"])
end
