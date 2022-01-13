# frozen_string_literal: true

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

        unless blockchain.gateway_class.implements?(:create_address!)
          Rails.logger.warn "Skip deposit coin address for blockchain #{payload}. It does not implement create_address!"
          return
        end

        payment_address = member.payment_address(blockchain)
        member.with_lock do
          payment_address.lock!
          if payment_address.address.present?
            Rails.logger.info { { message: 'Skip coin deposit address. It exists', member_id: member.id, blockchain_id: blockchain.id } }
            return
          end

          member_addresses = member.payment_addresses.active.joins(:blockchain).where(blockchains: { address_type: blockchain.address_type }).pluck(:address)
          blockchain_address = BlockchainAddress.find_by(address: member_addresses, address_type: blockchain.address_type)
          result = if blockchain_address.present?
                     { address: blockchain_address.address }
                   else
                     Rails.logger.info { { message: 'Coin deposit address', member_id: member.id, blockchain_id: blockchain.id } }
                     blockchain.create_address! || raise("No result when creating adress for #{member.id} #{currency}")
                   end
          payment_address.update!(result.slice(:address, :secret, :details))
        end
        Rails.logger.info { { message: 'Payment address is updated', payment_address_id: payment_address.id, member_id: member.id, blockchain_id: blockchain.id } }
        payment_address.create_contract_accounts if payment_address.blockchain.client == 'solana'
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
