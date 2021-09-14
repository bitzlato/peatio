# Run polling process for supported gateways
module Jobs
  module Cron
    module TransfersPolling
      TIMEOUT = 10
      def self.process
        return unless Rails.env.production?

        Blockchain.active.find_each do |b|
          poll_deposits b if b.gateway_class.implements? :poll_deposits!
          poll_withdraws b if b.gateway_class.implements? :poll_withdraws!
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
