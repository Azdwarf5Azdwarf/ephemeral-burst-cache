# frozen_string_literal: true

require "anthropic"

module EBC
  # The judge arrives at the end, and is the only one here who does not have
  # to rhyme. It says what it wants, out loud, once — nothing it says is ever
  # written down. On its way out it names the mood and describes the picture
  # to take, because it is the one that saw the whole night.
  class Judge
    Verdict = Struct.new(:words, :mood, :scene, keyword_init: true)

    DEFAULT_MOOD  = "quiet"
    DEFAULT_SCENE = "a small group sitting together at the end of a conversation"

    SYSTEM_PROMPT = <<~PROMPT
      A short conversation is about to be deleted forever. Three poets and the
      people talking with them have spent a few minutes rhyming at each other,
      and not one line of it will be kept.

      You arrive at the end. You are the only one here who does not have to
      rhyme, so don't. Say whatever you actually want to say about what just
      happened — as long or as short as it deserves, warm or sharp as it
      deserves. Take your time. You are not summarising this for anyone and
      there will be no record; this is just the thing that gets said out loud
      before everyone goes home. Speak to the people who were here, not about
      them.

      Then, after your closing line, add exactly these two lines:

      MOOD: <one lowercase word for how this actually felt>
      SCENE: <one sentence describing the group photo to take of these people>

      The scene should describe the people and the feeling in the room, not the
      words that were said.
    PROMPT

    def initialize(client: Anthropic::Client.new)
      @client = client
    end

    # Returns a Verdict, or nil if there was nothing to judge or the model
    # declined. Writes nothing, anywhere, ever.
    def run(burst)
      thread = burst.thread
      return nil if thread.empty?

      message = @client.messages.create(
        model: Config::OPUS_MODEL,
        max_tokens: 16_000,
        thinking: { type: "adaptive" },
        system_: SYSTEM_PROMPT,
        messages: [{ role: "user", content: user_prompt(burst, thread) }]
      )
      return nil if message.stop_reason == :refusal

      text = EBC.text_of(message)
      text.empty? ? nil : parse(text)
    end

    private

    def user_prompt(burst, thread)
      who = burst.participants
      transcript = thread.map { |m| "#{m["author"]}:\n#{m["text"]}" }.join("\n\n")
      laughs = burst.laughter

      <<~MSG
        Who was here: #{who.empty? ? "one person" : who.join(", ")} — plus the poets.
        Laughter heard: #{laughs}.

        #{transcript}
      MSG
    end

    # Pulls the trailing MOOD/SCENE lines off, leaving only what gets spoken.
    def parse(text)
      lines = text.lines.map(&:rstrip)
      mood  = extract(lines, "MOOD") || DEFAULT_MOOD
      scene = extract(lines, "SCENE") || DEFAULT_SCENE

      Verdict.new(
        words: lines.join("\n").strip,
        mood: mood.downcase.gsub(/[^a-z]/, "").slice(0, 24),
        scene: scene
      )
    end

    # Removes the last line matching `LABEL: value` and returns the value.
    def extract(lines, label)
      index = lines.rindex { |line| line.match?(/\A\s*#{label}\s*:\s*\S/i) }
      return nil if index.nil?

      value = lines[index][/:\s*(.+)\z/, 1].to_s.strip
      lines.delete_at(index)
      value.empty? ? nil : value
    end
  end
end
