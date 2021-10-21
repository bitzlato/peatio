# frozen_string_literal: true

module Jobs
  module Cron
    class AllowanceCollector
      JOB_PAUSE = 10

      def self.process(job_pause = JOB_PAUSE)
        Rails.logger.info('Check collectable balances on PaymentAddresses')
        PaymentAddress.collection_required.lock.each do |payment_address|
          next unless blockchain.payment_address.allowance_enabled
          next unless payment_address.has_collectable_balances?

          if payment_address.blockchain.high_transaction_price_at.present?
            Rails.logger.warn(message: 'Collecting is skipped. Gas price is too high', payment_address_id: payment_address.id)
            next
          end

          payment_address.blockchain.gateway.transfer_from!(address: payment_address.address, secret: payment_address.secret, blockchain_address: payment_address.blockchain_address, contract_address: payment_address.currency.contract_address)
        end

        sleep job_pause
      end
    end
  end
end
