# frozen_string_literal: true

require_relative "ebc/config"
require_relative "ebc/grok_client"
require_relative "ebc/sonnet_agent"
require_relative "ebc/burst"
require_relative "ebc/judge"
require_relative "ebc/group_photo"

module EBC
  # Both the poets and the judge talk to Claude, and both want the words out.
  def self.text_of(message)
    message.content.filter_map { |block| block.text if block.type == :text }.join("\n").strip
  end
end
