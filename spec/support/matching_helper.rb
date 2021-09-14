# encoding: UTF-8
# frozen_string_literal: true

def who_is_billionaire
  member = create(:member, :level_3)
  member.get_account(:btc).update_attributes(
    locked: '1000000000.0'.to_d, balance: '1000000000.0'.to_d
  )
  member.get_account(:usd).update_attributes(
    locked: '1000000000.0'.to_d, balance: '1000000000.0'.to_d
  )
  member
end

def print_time(time_hash)
  msg = time_hash.map { |k, v| "#{k}: #{v}" }.join(', ')
  puts "    \u25BC #{msg}"
end

module Matching
  class << self
    @@mock_order_id = 10_000

    def mock_limit_order(attrs)
      @@mock_order_id += 1
      Matching::LimitOrder.new({
        id: @@mock_order_id,
        timestamp: Time.now.to_i,
        volume: rand(1..10),
        price: rand(3000..5999),
        market: 'btc_usd'
      }.merge(attrs))
    end

    def mock_market_order(attrs)
      @@mock_order_id += 1
      Matching::MarketOrder.new({
        id: @@mock_order_id,
        timestamp: Time.now.to_i,
        volume: rand(1..10),
        locked: rand(15000..29999),
        market: 'btc_usd'
      }.merge(attrs))
    end
  end
end
