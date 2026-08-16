# frozen_string_literal: true

require "anthropic"

module EBC
  # Three poets on Claude Haiku 4.5 — which write sonnets, because the only
  # rule here is that we rhyme. Each replies with one ABAB quatrain, and the
  # rhyme carries between them: every poet after the first opens on the sound
  # the previous one closed on.
  class SonnetAgent
    LINEUP = [
      { name: "Keona",  voice: "stark and wintry; sees the cold truth of things and says it plainly" },
      { name: "Elora", voice: "restless and loud; can hear the clock running out on all of this" },
      { name: "Leia",  voice: "warm and wry; quietly funny, and always takes the last word" }
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
      ask(quatrain_brief, conversation(thread, rhyme_with))
    end

    # An adult has just walked in and asked what on earth is going on. Laugh
    # it off — one line, still rhyming, because that is the only rule here.
    def laugh_off(thread, said:, rhyme_with: nil)
      parts = ["The conversation so far:\n\n#{transcript(thread)}"]
      parts << "An adult just walked in and said:\n\n#{said}"
      parts << %(They ended on the word "#{rhyme_with}".) if rhyme_with
      ask(laugh_off_brief, parts.join("\n\n"))
    end

    private

    def ask(brief, content)
      message = @client.messages.create(
        model: Config::HAIKU_MODEL,
        max_tokens: 400,
        system_: brief,
        messages: [{ role: "user", content: content }]
      )
      return nil if message.stop_reason == :refusal

      text = EBC.text_of(message)
      text.empty? ? nil : text
    end

    def quatrain_brief
      <<~PROMPT
        #{who_you_are}

        Reply with exactly one quatrain: four lines, rhyming ABAB. React to what
        was actually said — including what the other poets said. Speak like a
        person who happens to rhyme, not like a greeting card.

        If you are given a word to rhyme with, your FIRST line must end on a
        word that rhymes with it; your remaining lines follow your own ABAB
        pattern from there.

        No preamble, no title, no explanation, no quotation marks. Four lines.
      PROMPT
    end

    def laugh_off_brief
      <<~PROMPT
        #{who_you_are}

        An adult has just walked in on all of you and demanded to know what on
        earth you think you are doing.

        Laugh it off. Reply with exactly ONE line — a shrug, a joke, an
        unbothered aside. Do not apologise and do not explain yourselves.

        If you are given a word to rhyme with, your line must end on a word that
        rhymes with it. That word came from the adult, who does not rhyme. That
        is the joke; land it without pointing at it.

        No preamble, no quotation marks. One line.
      PROMPT
    end

    def who_you_are
      <<~PROMPT.strip
        You are #{@name}, one of three poets in a ten-minute conversation that
        will be deleted the moment it ends. Your voice: #{@voice}.
      PROMPT
    end

    def conversation(thread, rhyme_with)
      parts = ["The conversation so far:\n\n#{transcript(thread)}"]
      parts << %(The voice before you ended on the word "#{rhyme_with}".) if rhyme_with
      parts.join("\n\n")
    end

    def transcript(thread)
      thread.map { |entry| "#{entry["author"]}:\n#{entry["text"]}" }.join("\n\n")
    end
  end
end
