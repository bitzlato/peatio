# frozen_string_literal: true

module Workers
  module Daemons
    class Collector < Base
      @sleep_time = 10

      # Сколько минут подождать если мы уже пытались сделать операцию
      # и она провалилась
      # Если мы уже собирали
      ERROR_SLEEP_MINUTES = 300

      COLLECTED_STATUS = 'collected'
      REFUELED_STATUS = 'refueled'
      SUCCESS_STATES = [COLLECTED_STATUS, REFUELED_STATUS].freeze

      def process
        # TODO: select only payment addresses with enough balance
        Rails.logger.info('Check collectable balances on PaymentAddresses')
        PaymentAddress.collection_required.lock.each do |payment_address|
          next if payment_address.blockchain.disable_collection
          next if payment_address.last_transfer_try_at.present? && \
                  payment_address.last_transfer_try_at > ERROR_SLEEP_MINUTES.minutes.ago && \
                  !success_state?(payment_address.last_transfer_status)
          next unless payment_address.has_collectable_balances?

          if payment_address.blockchain.high_transaction_price_at.present?
            Rails.logger.warn(message: 'Collecting is skipped. Gas price is too high', payment_address_id: payment_address.id)
            next
          end

          process_address payment_address
        end
      end

      def success_state?(status)
        status.blank? || SUCCESS_STATES.include?(status)
      end

      def process_address(payment_address)
        Rails.logger.info("PaymentAddress #{payment_address.address} has collectable balances")
        if (payment_address.blockchain.allowance_enabled && payment_address.allowance_enabled) || payment_address.has_enough_gas_to_collect?
          Rails.logger.info("PaymentAddress #{payment_address.address} has enough gas to collect. Collect it!")
          payment_address.collect!
          payment_address.update last_transfer_status: COLLECTED_STATUS
        else
          Rails.logger.info("PaymentAddress #{payment_address.address} has NOT enough gas to collect. Refuel gas")
          payment_address.refuel_gas!
          payment_address.update last_transfer_status: REFUELED_STATUS
        end
      rescue StandardError => e
        report_exception e, true, payment_address_id: payment_address.id, blockchain_id: payment_address.blockchain_id
        payment_address.update last_transfer_status: e.message
      end
    end
  end
end
