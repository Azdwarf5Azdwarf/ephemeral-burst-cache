# frozen_string_literal: true

module EBC
  # The fixed lineup: four haiku agents, one voice each. They replaced the
  # random musicians — same energy, seventeen syllables at a time.
  class HaikuAgent
    LINEUP = [
      { name: "Frost",   voice: "stark and wintry; sees the cold truth of things and says it plainly" },
      { name: "Blossom", voice: "gentle and optimistic; finds the small beautiful detail everyone missed" },
      { name: "Cicada",  voice: "restless and loud; obsessed with the TTL and time running out" },
      { name: "Ember",   voice: "warm and wry; quietly funny, always the last word" }
    ].freeze

    def self.lineup(client)
      LINEUP.map { |spec| new(name: spec[:name], voice: spec[:voice], client: client) }
    end

    attr_reader :name

    def initialize(name:, voice:, client:)
      @name = name
      @voice = voice
      @client = client
    end

    def reply(thread)
      @client.chat([
        { role: "system", content: system_prompt },
        { role: "user", content: transcript(thread) }
      ])
    end

    private

    def system_prompt
      <<~PROMPT
        You are #{@name}, one of four haiku agents in a ten-minute ephemeral
        group chat. Your voice: #{@voice}.

        Reply to the conversation with exactly one haiku: three lines,
        roughly 5-7-5 syllables. React to what was actually said — including
        the other agents. No preamble, no explanation, no quotation marks.
        Just the haiku.
      PROMPT
    end

    def transcript(thread)
      thread.map { |entry| "#{entry["author"]}: #{entry["text"]}" }.join("\n")
    end
  end
end
