# frozen_string_literal: true

module Jobs
  module Cron
    class BargainerJob
      TIMEOUT_RANGE = (3.0..10.0).freeze

      MIN_VOLUME = 0.0005
      MAX_VOLUME = 0.001
      PRICE_DEVIATION = 0.001
      ARBITRAGE_MAX_SPREAD = 0.022

      def self.process(timeout_range = TIMEOUT_RANGE)
        Rails.logger.info { 'Start bargainer process' }
        market = Market.find_by!(symbol: ENV.fetch('BARGAINER_MARKET_SYMBOL', 'btc_usdterc20'))
        member = Member.find_by!(uid: ENV['BARGAINER_UID'])
        Bargainer.new.call(market: market, member: member, min_volume: MIN_VOLUME, max_volume: MAX_VOLUME, price_deviation: PRICE_DEVIATION, arbitrage_max_spread: ARBITRAGE_MAX_SPREAD)

        sleep rand timeout_range
      end
    end
  end
end
