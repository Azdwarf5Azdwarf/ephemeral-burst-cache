# frozen_string_literal: true

module EBC
  module Config
    REDIS_URL   = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")
    DEFAULT_TTL = 600 # 10 minutes

    # Grok is the camera and nothing else. It does not speak.
    XAI_API_KEY      = ENV["XAI_API_KEY"]
    XAI_BASE_URL     = ENV.fetch("XAI_BASE_URL", "https://api.x.ai/v1")
    GROK_IMAGE_MODEL = ENV.fetch("GROK_IMAGE_MODEL", "grok-2-image")

    # Claude does the talking: three Haiku 4.5 poets, then one Opus judge.
    ANTHROPIC_API_KEY = ENV["ANTHROPIC_API_KEY"]
    HAIKU_MODEL       = ENV.fetch("HAIKU_MODEL", "claude-haiku-4-5")
    OPUS_MODEL        = ENV.fetch("OPUS_MODEL", "claude-opus-4-8")

    # The photo is the only thing that outlives a burst.
    FRAME_COUNT = Integer(ENV.fetch("EBC_FRAME_COUNT", "4"))
    PHOTO_DIR   = ENV.fetch("EBC_PHOTO_DIR", "photos")
  end
end
