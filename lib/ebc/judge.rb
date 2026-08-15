# frozen_string_literal: true

require "anthropic"

module EBC
  # An adult opens the door on all this.
  #
  # It is the only voice here that does not have to rhyme, and it is not
  # impressed. It says its piece once — nothing it says is ever written down —
  # and on the way out it names the mood and describes the picture to take,
  # because it is the one that walked in and saw the state of the room.
  #
  # It does not get the last word. The room laughs it off and carries on.
  class Judge
    Verdict = Struct.new(:words, :mood, :scene, keyword_init: true)

    DEFAULT_MOOD  = "quiet"
    DEFAULT_SCENE = "a small group sitting together at the end of a conversation"

    OPENER = "Vad fan håller ni på med?"

    SYSTEM_PROMPT = <<~PROMPT
      You are an adult, and you have just opened the door on this.

      Three poets and the people with them have spent the last few minutes in
      a room rhyming nonsense at each other. You were not part of it. You do
      not know how long it has been going on. You have simply walked in.

      Begin with exactly this line, alone on its first line, unchanged:

      #{OPENER}

      Then keep going in your own words, in whatever language they were using.
      You are the only one here who does not have to rhyme, so don't — you are
      the one adult in a room of people who have clearly been at this a while.
      Be baffled. Be exasperated. Be funny about it if it's funny. You are
      allowed to be secretly fond of them; you are not allowed to say so.

      Speak to them, not about them. Say your piece and stop — you are not
      summing anything up, and nobody is writing this down. Keep it short
      enough that it lands like someone actually talking.

      Then, after your last line, add exactly these two lines:

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

      <<~MSG
        Who was here: #{who.empty? ? "one person" : who.join(", ")} — plus the poets.

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
