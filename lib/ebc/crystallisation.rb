# frozen_string_literal: true

require "json"
require "fileutils"

module EBC
  # Crystallisation: the only output that survives a burst.
  #
  # Grok reads the thread and writes three meme image prompts; Grok's image
  # model renders them. The images land in Config::MEME_DIR. The thread
  # itself dies with its TTL like everything else.
  class Crystallisation
    PROMPT_WRITER = <<~PROMPT
      You turn short chaotic group-chat threads (a human plus four haiku
      agents) into prompts for an image generation model. Each prompt
      describes one meme image capturing a moment, running joke, or mood
      from the thread. Be visual and specific. Any text inside the image
      must be a short caption, nothing longer.
    PROMPT

    def initialize(burst, client: GrokClient.new)
      @burst = burst
      @client = client
    end

    def run(count: Config::MEME_COUNT, out_dir: Config::MEME_DIR)
      thread = @burst.thread
      raise "thread is empty — nothing to crystallise" if thread.empty?

      prompts = meme_prompts(thread, count)
      FileUtils.mkdir_p(out_dir)

      prompts.each_with_index.map do |prompt, index|
        path = File.join(out_dir, "#{@burst.uuid}-meme-#{index + 1}.png")
        File.binwrite(path, @client.image_bytes(prompt))
        { prompt: prompt, path: path }
      end
    end

    private

    def meme_prompts(thread, count)
      transcript = thread.map { |m| "#{m["author"]}: #{m["text"]}" }.join("\n")
      response = @client.chat([
        { role: "system", content: PROMPT_WRITER },
        { role: "user", content: <<~MSG }
          Thread:

          #{transcript}

          Write #{count} distinct meme image prompts based on this thread.
          Respond with a JSON array of exactly #{count} strings and nothing else.
        MSG
      ])
      parse_prompts(response, count)
    end

    def parse_prompts(response, count)
      json = response[/\[.*\]/m]
      prompts = json ? JSON.parse(json).map(&:to_s) : []
      prompts = response.lines.map(&:strip).reject(&:empty?) if prompts.empty?
      raise GrokClient::Error, "could not extract meme prompts" if prompts.empty?

      prompts.first(count)
    rescue JSON::ParserError
      response.lines.map(&:strip).reject(&:empty?).first(count)
    end
  end
end
