# frozen_string_literal: true

module Jobs
  module Cron
    class Collector
      def self.process
        return if Rails.env.production?

        # TODO: select only payment addresses with enough balance
        PaymentAddress.collection_required.lock.each do |pa|
          next unless payment_address.has_collectable_balances?

          process_address payment_address
        end
        sleep 300
      end

      def self.process_address(payment_address)
        return unless payment_address.has_collectable_balances?

        if payment_address.has_enough_gas_to_collect?
          payment_address.collect!
        else
          payment_address.refuel_gas!
        end
      rescue StandardError => err
        report_exception err, true, payment_address_id: payment_address.id
      end
    end
  end
end
