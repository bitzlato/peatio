# frozen_string_literal: true

# K-line point is represented as array of 5 numbers:
# [timestamp, open_price, max_price, min_price, last_price, period_volume]

module Workers
  module Daemons
    class CronJob < Base
      JOBS = [
        Jobs::Cron::KLine,
        Jobs::Cron::Ticker,
        Jobs::Cron::StatsMemberPnl,
        # Jobs::Cron::AML,
        Jobs::Cron::Refund,
        Jobs::Cron::WalletBalances,
        Jobs::Cron::TransfersPolling,
        Jobs::Cron::PaymentAddressBalancer,
        Jobs::Cron::RemoveInvoicedDeposits
      ].freeze

      def run
        @threads = JOBS.map { |j| Thread.new { process(j) } }
        @threads.map(&:join)
      end

      def process(service)
        service.process while running
      end

      def stop
        super
        Array(@threads).each { |t| Thread.kill t }
      end
    end
  end
end
