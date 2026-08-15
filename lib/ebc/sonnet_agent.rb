# frozen_string_literal: true

require "anthropic"

module EBC
  # Three poets on Claude Haiku 4.5 — which write sonnets, because the only
  # rule here is that we rhyme. Each replies with one ABAB quatrain, and the
  # rhyme carries between them: every poet after the first opens on the sound
  # the previous one closed on.
  class SonnetAgent
    LINEUP = [
      { name: "Frost",  voice: "stark and wintry; sees the cold truth of things and says it plainly" },
      { name: "Cicada", voice: "restless and loud; can hear the clock running out on all of this" },
      { name: "Ember",  voice: "warm and wry; quietly funny, and always takes the last word" }
    ].freeze

    def self.lineup(client = Anthropic::Client.new)
      LINEUP.map { |spec| new(name: spec[:name], voice: spec[:voice], client: client) }
    end

    # The sound a stanza closed on, for the next poet to pick up. Returns nil
    # when there is nothing to rhyme with — an empty stanza, or a line that
    # was nothing but punctuation.
    def self.rhyme_word(stanza)
      line = stanza.to_s.lines.map(&:strip).reject(&:empty?).last
      return nil if line.nil?

      word = line.split(/\s+/).last.to_s.gsub(/[^[:alnum:]']/, "").downcase
      word.empty? ? nil : word
    end

    attr_reader :name

    def initialize(name:, voice:, client:)
      @name = name
      @voice = voice
      @client = client
    end

    # `rhyme_with` is the previous poet's closing word, or nil to start fresh.
    def reply(thread, rhyme_with: nil)
      message = @client.messages.create(
        model: Config::HAIKU_MODEL,
        max_tokens: 400,
        system_: system_prompt,
        messages: [{ role: "user", content: user_prompt(thread, rhyme_with) }]
      )
      return nil if message.stop_reason == :refusal

      text = EBC.text_of(message)
      text.empty? ? nil : text
    end

    private

    def system_prompt
      <<~PROMPT
        You are #{@name}, one of three poets in a ten-minute conversation that
        will be deleted the moment it ends. Your voice: #{@voice}.

        Reply with exactly one quatrain: four lines, rhyming ABAB. React to what
        was actually said — including what the other poets said. Speak like a
        person who happens to rhyme, not like a greeting card.

        No preamble, no title, no explanation, no quotation marks. Four lines.
      PROMPT
    end

    def user_prompt(thread, rhyme_with)
      parts = ["The conversation so far:\n\n#{transcript(thread)}"]
      if rhyme_with
        parts << <<~HANDOFF.strip
          The poet before you ended on the word "#{rhyme_with}". Your first line
          must end on a word that rhymes with "#{rhyme_with}". Your remaining
          lines follow your own ABAB pattern from there.
        HANDOFF
      end
      parts.join("\n\n")
    end

    def transcript(thread)
      thread.map { |entry| "#{entry["author"]}:\n#{entry["text"]}" }.join("\n\n")
    end
  end
end
