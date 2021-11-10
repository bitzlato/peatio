# frozen_string_literal: true

module Jobs
  module Cron
    class BargainerJob
      JOB_TIMEOUT = 30.seconds

      MIN_VOLUME = 0.0005
      MAX_VOLUME = 0.001
      PRICE_DEVIATION = 0.001

      def self.process(job_timeout = JOB_TIMEOUT)
        market = Market.find_by!(symbol: ENV.fetch('BARGAINER_MARKET_SYMBOL', 'btc_usdterc20'))
        member = Member.find_by!(uid: ENV['BARGAINER_UID'])
        Bargainer.new.call(market: market, member: member, min_volume: MIN_VOLUME, max_volume: MAX_VOLUME, price_deviation: PRICE_DEVIATION)

        sleep job_timeout
      end
    end
  end
end
