# frozen_string_literal: true

require 'belomor_client'

module Workers
  module AMQP
    class DepositCoinAddress < Base
      def process(payload)
        payload.symbolize_keys!

        member = Member.find payload[:member_id]
        blockchain = Blockchain.find payload[:blockchain_id]

        if blockchain.enable_invoice?
          Rails.logger.warn "Skip deposit coin address for invoicable blockchain #{payload}"
          return
        end

        payment_address = member.payment_address(blockchain)
        member.with_lock do
          payment_address.lock!
          if payment_address.address.present?
            Rails.logger.info { { message: 'Skip coin deposit address. It exists', member_id: member.id, blockchain_id: blockchain.id } }
            return
          end

          Rails.logger.info { { message: 'Coin deposit address', member_id: member.id, blockchain_id: blockchain.id } }
          result = BelomorClient.new(app_key: 'peatio', blockchain_key: blockchain.key).create_address(owner_id: "user:#{member.uid}")
          payment_address.update!(address: result['address'])
        end
        Rails.logger.info { { message: 'Payment address is updated', payment_address_id: payment_address.id, member_id: member.id, blockchain_id: blockchain.id } }
        payment_address.create_token_accounts
        payment_address.trigger_address_event if payment_address.address.present?

      # Don't re-enqueue this job in case of error.
      # The system is designed in such way that when user will
      # request list of accounts system will ask to generate address again (if it is not generated of course).
      rescue StandardError => e
        Rails.logger.error(e)
        raise e if is_db_connection_error?(e)

        report_exception(e, true, payload)
      end
    end
  end
end
