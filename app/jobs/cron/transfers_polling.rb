# Run polling process for supported gateways
module Jobs
  module Cron
    module TransfersPolling
      TIMEOUT = 10
      def self.process
        Blockchain.active.find_each do |b|
          poll_deposits b if b.implements? :deposits_polling
          poll_withdraws b if b.implements? :withdraws_polling
        end
        sleep TIMEOUT
      rescue StandardError => e
        report_exception(e)
      end

      def self.poll_withdraws(b)
        b.gateway.poll_withdraws!
      rescue StandardError => e
        report_exception(e)
      end

      def self.poll_deposits(b)
        b.gateway.poll_deposits!
      rescue StandardError => e
        report_exception(e)
      end
    end
  end
end
