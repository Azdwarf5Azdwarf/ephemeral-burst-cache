# frozen_string_literal: true

require "securerandom"
require "time"
require "json"
require "redis"

module EBC
  # A burst: a short-lived shared conversation living entirely in Redis
  # under burst:{uuid}:*, with a hard TTL. When the TTL fires, the whole
  # namespace disappears — that is the feature.
  class Burst
    class Dead < StandardError; end

    def self.redis
      @redis ||= Redis.new(url: Config::REDIS_URL)
    end

    def self.start(ttl: Config::DEFAULT_TTL)
      burst = new(SecureRandom.uuid)
      meta = {
        uuid: burst.uuid,
        started_at: Time.now.utc.iso8601,
        ttl: ttl,
        status: "live"
      }
      redis.set(burst.key(:meta), meta.to_json, ex: ttl)
      burst
    end

    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
    end

    def key(suffix)
      "burst:#{uuid}:#{suffix}"
    end

    def meta
      raw = redis.get(key(:meta))
      raw && JSON.parse(raw)
    end

    def alive?
      !meta.nil?
    end

    def ttl_remaining
      redis.ttl(key(:meta))
    end

    def post(author, text)
      remaining = ttl_remaining
      raise Dead, "burst #{uuid} is dead or never existed" unless remaining.positive?

      entry = { author: author, text: text, at: Time.now.utc.iso8601 }
      redis.rpush(key(:thread), entry.to_json)
      # The thread never outlives the burst meta.
      redis.expire(key(:thread), remaining)
      entry
    end

    def thread
      redis.lrange(key(:thread), 0, -1).map { |raw| JSON.parse(raw) }
    end

    def kill
      keys = redis.keys("burst:#{uuid}:*")
      keys.empty? ? 0 : redis.del(*keys)
    end

    private

    def redis
      self.class.redis
    end
  end
end
