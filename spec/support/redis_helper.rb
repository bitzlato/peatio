# frozen_string_literal: true

module RedisTestHelper
  def clear_redis
    Rails.cache.redis.flushall
  end
end

RSpec.configure { |config| config.include RedisTestHelper }
