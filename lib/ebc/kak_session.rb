# frozen_string_literal: true

require "rbconfig"
require "tmpdir"
require "shellwords"

module EBC
  # A live, read-and-speak view of a burst inside kakoune. The poets' replies
  # stream into a fifo-backed buffer as they happen (KakPoller writes them);
  # <a-s> opens a prompt that posts what you type back into the burst, same
  # as `burst say` — it round-trips through Redis, there's no local echo.
  #
  # Nothing here outlives the kakoune session: the fifo, the kakscript, and
  # the poller's logfile all live in one tmpdir that's removed on exit, and
  # the poller itself is killed whether kakoune quits cleanly or not.
  class KakSession
    class Error < StandardError; end

    POLL_INTERVAL = 1 # seconds — plain polling, no pub/sub

    def initialize(burst, root: File.expand_path("../..", __dir__))
      @burst = burst
      @root = root
    end

    def run
      ensure_kak_installed!

      Dir.mktmpdir("ebc-kak") do |tmp|
        fifo = File.join(tmp, "thread.fifo")
        make_fifo(fifo)
        poller_pid = spawn_poller(fifo, tmp)

        begin
          script = write_kakscript(tmp, fifo, poller_pid)
          system("kak", "-n", "-e", "source '#{script}'")
        ensure
          kill_poller(poller_pid)
        end
      end
    end

    private

    def ensure_kak_installed!
      return if system("command -v kak > /dev/null 2>&1")

      raise Error, "kak not found — install kakoune to use `burst kak` (https://kakoune.org)"
    end

    def make_fifo(path)
      raise Error, "could not create fifo at #{path}" unless system("mkfifo", path)
    end

    # Opening a fifo for writing blocks until something opens it for
    # reading — and kak (the reader) doesn't exist yet at this point. So the
    # poller's stdout redirection must NOT be resolved by us: Process.spawn's
    # out:/err: options open the file in *this* process before forking,
    # which would deadlock here (verified — it does, hangs forever). Handing
    # the whole "ruby ... > fifo" line to /bin/sh instead means the shell's
    # child process does that blocking open on its own time, once forked,
    # which doesn't block us. kak opens the read end moments later and
    # unblocks it.
    def spawn_poller(fifo, tmp)
      log = File.join(tmp, "poller.log")
      cmd = [
        RbConfig.ruby, bin_burst, "kak-poller", @burst.uuid, POLL_INTERVAL.to_s
      ].map { |part| Shellwords.escape(part) }.join(" ")
      Process.spawn("/bin/sh", "-c", "exec #{cmd} > #{Shellwords.escape(fifo)} 2> #{Shellwords.escape(log)}")
    end

    def kill_poller(pid)
      Process.kill("TERM", pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
      # already gone — it hit EPIPE on its own, or kak's BufCloseFifo hook
      # beat us to it.
    end

    def bin_burst
      File.join(@root, "bin", "burst")
    end

    def write_kakscript(tmp, fifo, poller_pid)
      path = File.join(tmp, "session.kak")
      File.write(path, kakscript(fifo, poller_pid, tmp))
      path
    end

    def kakscript(fifo, poller_pid, tmp)
      bufname = "*burst-#{@burst.uuid[0, 8]}*"
      say = [RbConfig.ruby, bin_burst, "say", @burst.uuid].map { |part| Shellwords.escape(part) }.join(" ")
      say_log = File.join(tmp, "say.log")

      <<~KAK
        edit! -fifo #{fifo} -scroll #{bufname}
        set-option buffer readonly true

        hook -always -once buffer BufCloseFifo .* %{
            nop %sh{ kill -TERM #{poller_pid} 2>/dev/null }
        }

        hook -once global WinCreate .* %{
            echo -markup "{Information}live burst — <a-s> to speak, :q to leave"
        }

        map global normal <a-s> ': prompt "say: " %{ nop %sh{ #{say} "$kak_text" >> #{say_log} 2>&1 & } }<ret>'
      KAK
    end
  end
end
