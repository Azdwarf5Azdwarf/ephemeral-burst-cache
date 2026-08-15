# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "tempfile"

module EBC
  # ElevenLabs. Scribe hears the room and tags what it hears — including
  # laughter, which is the whole reason it's here. TTS gives the judge a
  # voice, so the verdict can be heard once and then be gone.
  class Voice
    class Error < StandardError; end

    # Scribe writes these inline in the transcript.
    LAUGHTER = /\((?:laughs?|laughter|laughing|chuckles?|giggles?)\)/i

    # Tried in order; the first one present gets to play the judge.
    PLAYERS = %w[afplay ffplay mpv aplay paplay].freeze

    def self.laughter_count(text)
      text.to_s.scan(LAUGHTER).length
    end

    def initialize(api_key: Config::ELEVENLABS_API_KEY, base_url: Config::ELEVENLABS_BASE_URL)
      raise Error, "ELEVENLABS_API_KEY is not set" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = base_url
    end

    # Audio file in, words out — with (laughs) left in place.
    def transcribe(path, model: Config::ELEVENLABS_STT_MODEL)
      raise Error, "no such audio file: #{path}" unless File.exist?(path)

      uri = URI("#{@base_url}/speech-to-text")
      request = Net::HTTP::Post.new(uri)
      request["xi-api-key"] = @api_key

      # The file has to stay open until the request is actually sent.
      response = File.open(path, "rb") do |file|
        request.set_form([
          ["file", file],
          ["model_id", model],
          ["tag_audio_events", "true"]
        ], "multipart/form-data")
        run(uri, request)
      end

      text = JSON.parse(response.body)["text"].to_s.strip
      raise Error, "empty transcript" if text.empty?

      text
    end

    # Returns mp3 bytes.
    def speak(text, voice_id: Config::ELEVENLABS_VOICE_ID, model: Config::ELEVENLABS_TTS_MODEL)
      uri = URI("#{@base_url}/text-to-speech/#{voice_id}")
      request = Net::HTTP::Post.new(uri)
      request["xi-api-key"] = @api_key
      request["Content-Type"] = "application/json"
      request.body = { text: text, model_id: model }.to_json

      run(uri, request).body
    end

    # Speaks the words and throws the audio away. Returns false when there is
    # no player on this machine — the caller falls back to printing, which is
    # every bit as unsaved.
    def play(audio_bytes)
      player = PLAYERS.find { |p| system("command -v #{p} > /dev/null 2>&1") }
      return false if player.nil?

      file = Tempfile.new(["judge", ".mp3"])
      begin
        file.binmode
        file.write(audio_bytes)
        file.close
        system(*player_command(player, file.path))
      ensure
        file.close unless file.closed?
        file.unlink
      end
    end

    private

    def player_command(player, path)
      case player
      when "ffplay" then [player, "-nodisp", "-autoexit", "-loglevel", "quiet", path]
      when "mpv"    then [player, "--really-quiet", path]
      else [player, path]
      end
    end

    def run(uri, request)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 180) do |http|
        http.request(request)
      end
      raise Error, "ElevenLabs #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      response
    end
  end
end
