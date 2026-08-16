# frozen_string_literal: true

require "anthropic"
require "fileutils"

module EBC
  # The last reasoning model in the pipeline: Claude Opus reads the thread,
  # cleans it up, and decides whether anything deserves to outlive the TTL.
  # If yes, a short distilled note lands in Config::SAVE_DIR. If not,
  # nothing is written and the burst dies clean.
  class Curator
    NOTHING = "NOTHING_WORTH_SAVING"

    SYSTEM_PROMPT = <<~PROMPT
      You are the final reasoning step of an ephemeral group-chat system.
      A ten-minute burst between a human and four haiku agents is about to
      be deleted forever. Your job is to clean the conversation up and
      decide what, if anything, is genuinely worth keeping: a real idea,
      a decision, a task, an insight, a line too good to lose.

      If nothing qualifies, reply with exactly #{NOTHING} and nothing else.
      Most bursts should die — be picky.

      Otherwise reply with a short markdown note: a one-line title, then
      the distilled points as brief bullets. No transcript, no filler,
      no commentary about the process.
    PROMPT

    def initialize(client: Anthropic::Client.new)
      @client = client
    end

    # Returns the path of the saved note, or nil when nothing was worth saving.
    def run(burst, out_dir: Config::SAVE_DIR)
      thread = burst.thread
      raise "thread is empty — nothing to curate" if thread.empty?

      note = distil(thread)
      return nil if note.nil?

      FileUtils.mkdir_p(out_dir)
      path = File.join(out_dir, "#{burst.uuid}.md")
      File.write(path, "#{note}\n")
      path
    end

    private

    def distil(thread)
      transcript = thread.map { |m| "#{m["author"]}: #{m["text"]}" }.join("\n")

      message = @client.messages.create(
        model: Config::OPUS_MODEL,
        max_tokens: 16_000,
        thinking: { type: "adaptive" },
        system_: SYSTEM_PROMPT,
        messages: [{ role: "user", content: "Thread:\n\n#{transcript}" }]
      )
      return nil if message.stop_reason == :refusal

      text = message.content.filter_map { |block| block.text if block.type == :text }
                    .join("\n").strip
      return nil if text.empty? || text.include?(NOTHING)

      text
    end
  end
end
