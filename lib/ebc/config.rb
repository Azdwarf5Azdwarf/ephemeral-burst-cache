# frozen_string_literal: true

module EBC
  module Config
    REDIS_URL   = ENV.fetch("REDIS_URL", "redis://127.0.0.1:6379/0")
    DEFAULT_TTL = 600 # 10 minutes

    # The Grok API is the only AI dependency: chat completions for the
    # haiku agents, image generation for the memes.
    XAI_API_KEY      = ENV["XAI_API_KEY"]
    XAI_BASE_URL     = ENV.fetch("XAI_BASE_URL", "https://api.x.ai/v1")
    GROK_CHAT_MODEL  = ENV.fetch("GROK_CHAT_MODEL", "grok-4-fast-non-reasoning")
    GROK_IMAGE_MODEL = ENV.fetch("GROK_IMAGE_MODEL", "grok-2-image")

    MEME_COUNT = 5
    MEME_DIR   = ENV.fetch("EBC_MEME_DIR", "memes")

    # Claude Opus is the single reasoning model: the last step of the
    # pipeline, cleaning up the thread and saving what matters (if anything).
    ANTHROPIC_API_KEY = ENV["ANTHROPIC_API_KEY"]
    OPUS_MODEL        = ENV.fetch("OPUS_MODEL", "claude-opus-5")
    SAVE_DIR          = ENV.fetch("EBC_SAVE_DIR", "saved")
  end
end
