# frozen_string_literal: true

module Jobs
  module Cron
    class BargainerJob
      JOB_TIMEOUT = 30.seconds

      def self.process(job_timeout = JOB_TIMEOUT)
        market = Market.find_by!(symbol: ENV.fetch('BARGAINER_MARKET_SYMBOL', 'btc_usdterc20'))
        member = Member.find_by!(uid: ENV['BARGAINER_UID'])
        volume = ENV.fetch('BARGAINER_VOLUME', 0.001).to_d
        Bargainer.new.call(market: market, member: member, volume: volume)

        sleep job_timeout
      end
    end
  end
end
