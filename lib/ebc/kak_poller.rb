# frozen_string_literal: true

module EBC
  # Watches a burst's thread and prints whatever's new since last time. Fed
  # into a kakoune fifo buffer by KakSession — it has no idea a fifo exists,
  # it just writes to its own stdout and lets the caller wire that up.
  class KakPoller
    def initialize(burst, interval: 1)
      @burst = burst
      @interval = interval
    end

    def run
      $stdout.sync = true
      seen = 0
      loop do
        entries = @burst.thread
        entries[seen..].each { |entry| $stdout.print(format_entry(entry)) } if entries.size > seen
        seen = entries.size
        sleep @interval
      end
    rescue Errno::EPIPE
      # kak closed the fifo's read end (buffer deleted or session ended) —
      # nothing left to watch.
    end

    private

    def format_entry(entry)
      body = entry["text"].to_s.each_line.map { |line| "  #{line.chomp}" }.join("\n")
      "#{entry["author"]}:\n#{body}\n\n"
    end
  end
end
