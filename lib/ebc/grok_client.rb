# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "base64"

module EBC
  # Thin client for the xAI (Grok) API — the project's only AI dependency.
  # Two endpoints: chat completions for the haiku agents and the meme
  # prompt writer, image generation for rendering the memes themselves.
  class GrokClient
    class Error < StandardError; end

    def initialize(api_key: Config::XAI_API_KEY, base_url: Config::XAI_BASE_URL)
      raise Error, "XAI_API_KEY is not set" if api_key.nil? || api_key.empty?

      @api_key = api_key
      @base_url = base_url
    end

    def chat(messages, model: Config::GROK_CHAT_MODEL, temperature: 1.0)
      body = post("/chat/completions", {
        model: model,
        messages: messages,
        temperature: temperature
      })
      content = body.dig("choices", 0, "message", "content")
      raise Error, "empty chat response" if content.nil? || content.strip.empty?

      content.strip
    end

    # Returns raw image bytes, whichever way the API hands them back.
    def image_bytes(prompt, model: Config::GROK_IMAGE_MODEL)
      body = post("/images/generations", {
        model: model,
        prompt: prompt,
        response_format: "b64_json"
      })
      data = body.dig("data", 0) or raise Error, "no image in response"

      return Base64.decode64(data["b64_json"]) if data["b64_json"]
      return download(data["url"]) if data["url"]

      raise Error, "image response had neither b64_json nor url"
    end

    private

    def post(path, payload)
      uri = URI("#{@base_url}#{path}")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 180) do |http|
        http.request(request)
      end
      raise Error, "xAI API #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def download(url)
      response = Net::HTTP.get_response(URI(url))
      raise Error, "image download failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
