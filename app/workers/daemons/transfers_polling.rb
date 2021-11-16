# frozen_string_literal: true

module Workers
  module Daemons
    class TransfersPolling < Base
      @sleep_time = 10

      def process
        return unless Rails.env.production?

        Blockchain.active.find_each do |b|
          poll_deposits b if b.gateway_class.implements? :poll_deposits!
          poll_withdraws b if b.gateway_class.implements? :poll_withdraws!
        end
      rescue StandardError => e
        report_exception(e)
      end

      def poll_withdraws(blockchain)
        blockchain.gateway.poll_withdraws!
      rescue StandardError => e
        report_exception(e)
      end

      def poll_deposits(blockchain)
        blockchain.gateway.poll_deposits!
      rescue StandardError => e
        report_exception(e)
      end
    end
  end
end
