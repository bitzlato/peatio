# frozen_string_literal: true

module Jobs
  module Cron
    class Collector
      def self.process
        # TODO: select only payment addresses with enough balance
        Rails.logger.info('Check collectable balances on PaymentAddresses')
        PaymentAddress.collection_required.lock.each do |payment_address|
          next unless payment_address.has_collectable_balances?

          process_address payment_address
        end
        sleep 10
      end

      def self.process_address(payment_address)
        return unless payment_address.has_collectable_balances?

        Rails.logger.info("PaymentAddress #{payment_address.address} has collectable balances")
        if payment_address.has_enough_gas_to_collect?
          Rails.logger.info("PaymentAddress #{payment_address.address} has enough gas to collect. Collect it!")
          payment_address.collect!
          payment_address.update last_transfer_status: :collected
        else
          Rails.logger.info("PaymentAddress #{payment_address.address} has NOT enough gas to collect. Refuel gas")
          payment_address.refuel_gas!
          payment_address.update last_transfer_status: :refueled
        end
      rescue StandardError => e
        report_exception e, true, payment_address_id: payment_address.id, blockchain_id: payment_address.blockchain_id
        payment_address.update last_transfer_status: e.message
      end
    end
  end
end
