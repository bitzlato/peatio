# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class DepositCoinAddress < Base
      def process(payload)
        payload.symbolize_keys!

        member = Member.find_by_id(payload[:member_id])
        unless member
          Rails.logger.warn do
            'Unable to generate deposit address.'\
            "Member with id: #{payload[:member_id]} doesn't exist"
          end
          return
        end

        wallet = Wallet.find_by_id(payload[:wallet_id])

        unless wallet
          Rails.logger.warn do
            'Unable to generate deposit address.'\
            "Deposit Wallet with id: #{payload[:wallet_id]} doesn't exist"
          end
          return
        end

        member.payment_address(wallet.id).tap do |pa|
          pa.with_lock do
            next if pa.address.present?

            # Supply address ID in case of BitGo address generation if it exists.
            result = wallet.create_address!

            if result.present?
              pa.update!(address: result[:address],
                         secret:  result[:secret],
                         details: { updated_at: pa.updated_at })
            end
          end

          pa.trigger_address_event unless pa.address.blank?
        end

      # Don't re-enqueue this job in case of error.
      # The system is designed in such way that when user will
      # request list of accounts system will ask to generate address again (if it is not generated of course).
      rescue StandardError => e
        raise e if is_db_connection_error?(e)

        report_exception(e)
      end
    end
  end
end
