# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class DepositCoinAddress < Base
      def process(payload)
        return if Rails.env.staging?
        payload.symbolize_keys!

        member = Member.find payload[:member_id]
        blockchain = Blockchain.find payload[:blockchain_id]

        if blockchain.enable_invoice?
          Rails.logger.warn "Skip deposit coin address for invoicable blockchain #{payload}"
          return
        end

        return unless blockchain.gateway_class.implements? :create_address!

        member.payment_address(blockchain).tap do |pa|
          pa.with_lock do
            return if pa.address.present?
            result = blockchain.create_address! || raise("No result when creating adress for #{member.id} #{currency.to_s}")

            pa.update!(address: result[:address],
                       secret:  result[:secret],
                       details: result[:details])
          end

          pa.trigger_address_event if pa.address.present?
        end

      # Don't re-enqueue this job in case of error.
      # The system is designed in such way that when user will
      # request list of accounts system will ask to generate address again (if it is not generated of course).
      rescue StandardError => e
        raise e if is_db_connection_error?(e)

        report_exception(e, true, payload)
      end
    end
  end
end
