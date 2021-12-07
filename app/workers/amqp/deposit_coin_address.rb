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

        unless ENV.true?('USE_PRIVATE_KEY') ? blockchain.gateway_class.implements?(:create_private_address!) : blockchain.gateway_class.implements?(:create_address!)
          Rails.logger.warn "Skip deposit coin address for blockchain #{payload}. It does not implement create_address!"
          return
        end

        member.payment_address(blockchain).tap do |pa|
          pa.with_lock do
            if pa.address.present?
              Rails.logger.info("Skip coin deposit adress for member_id:#{member.id}, blockchain_id:#{blockchain.id}. It exists")
              next
            else
              Rails.logger.info("Coin deposit adress for member_id:#{member.id}, blockchain_id:#{blockchain.id}")
            end
            if ENV.true?('USE_PRIVATE_KEY')
              blockchain_address = blockchain.create_private_address! || raise("No result when creating adress for #{member.id} #{currency}")
              pa.update!(address: blockchain_address.address)
            else
              result = blockchain.create_address! || raise("No result when creating adress for #{member.id} #{currency}")
              pa.update!(address: result[:address],
                         secret: result[:secret],
                         details: result[:details])
            end
            Rails.logger.info("Coined #{pa.address} for member_id:#{member.id}, blockchain_id:#{blockchain.id}")
          end

          pa.trigger_address_event if pa.address.present?
        end

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
