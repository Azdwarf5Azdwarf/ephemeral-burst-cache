# frozen_string_literal: true

# No dotenv dependency — just enough to pull KEY=VALUE lines from .env into
# ENV before Config reads them. Real environment variables always win.
env_file = File.expand_path("../.env", __dir__)
if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    key, value = line.split("=", 2)
    next unless key && value

    ENV[key.strip] ||= value.strip.gsub(/\A["']|["']\z/, "")
  end
end

require_relative "ebc/config"
require_relative "ebc/grok_client"
require_relative "ebc/sonnet_agent"
require_relative "ebc/burst"
require_relative "ebc/judge"
require_relative "ebc/group_photo"
require_relative "ebc/kak_poller"
require_relative "ebc/kak_session"

module EBC
  # Both the poets and the judge talk to Claude, and both want the words out.
  def self.text_of(message)
    message.content.filter_map { |block| block.text if block.type == :text }.join("\n").strip
  end
end
