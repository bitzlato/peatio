# frozen_string_literal: true

class OrdersRater
  include Singleton

  PREFIX = 'orders_rater'
  SEP = ':'

  PERIODS = {
    'second' => 1,
    'minut' => 60
  }.freeze

  def initialize
    @redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end

  # @param uid - member uid
  # @param period - minut, second
  def rates(uid)
    PERIODS.keys.each_with_object({}) do |period, ag|
      ag[period] = @redis.eval "return #redis.call('keys', '" + [PREFIX, uid, period, '*'].join(SEP) + "')"
    end
  end

  def order(uid, order_id)
    PERIODS.each_pair do |period, ex|
      @redis.set [PREFIX, uid, period, order_id].join(SEP), order_id.to_s, ex: ex
    end
  end
end
