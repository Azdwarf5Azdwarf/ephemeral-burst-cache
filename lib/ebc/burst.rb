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

    def self.start(ttl: Config::DEFAULT_TTL, host: "you")
      burst = new(SecureRandom.uuid)
      meta = {
        uuid: burst.uuid,
        started_at: Time.now.utc.iso8601,
        ttl: ttl,
        status: "live"
      }
      redis.set(burst.key(:meta), meta.to_json, ex: ttl)
      burst.add_participant(host)
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
      remaining = alive_ttl
      entry = { author: author, text: text, at: Time.now.utc.iso8601 }
      redis.rpush(key(:thread), entry.to_json)
      # The thread never outlives the burst meta.
      redis.expire(key(:thread), remaining)
      entry
    end

    def thread
      redis.lrange(key(:thread), 0, -1).map { |raw| JSON.parse(raw) }
    end

    # Everyone who showed up, in the order they arrived — the cast of the
    # photo. Like everything else here, they expire with the burst.
    def add_participant(name)
      remaining = alive_ttl
      return name if participants.include?(name)

      redis.rpush(key(:participants), name)
      redis.expire(key(:participants), remaining)
      name
    end

    def participants
      redis.lrange(key(:participants), 0, -1)
    end

    def kill
      keys = redis.keys("burst:#{uuid}:*")
      keys.empty? ? 0 : redis.del(*keys)
    end

    private

    # Nothing in a burst may outlive the burst itself, so every write checks
    # the clock first and pins the new key to whatever time is left.
    def alive_ttl
      remaining = ttl_remaining
      raise Dead, "burst #{uuid} is dead or never existed" unless remaining.positive?

      remaining
    end

    def redis
      self.class.redis
    end
  end
end
