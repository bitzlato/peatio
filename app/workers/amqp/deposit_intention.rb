# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class DepositIntention < Base
      def process(payload)
        payload.symbolize_keys!


        deposit = Deposit.find_by_id(payload[:deposit_id])
        unless deposit
          Rails.logger.warn do
            'Unable to make deposit.'\
            "Deposit with id: #{payload[:deposit_id]} doesn't exist"
          end
          return
        end

        wallet = Wallet.deposit_wallet(deposit.currency.id)

        unless wallet.present?
          Rails.logger.warn do
            'Unable to make deposit.'\
            "No deposit wallet for #{deposit.currency}"
          end
          return
        end


        wallet_service = WalletService.new(wallet)
        wallet_service.create_invoice! deposit
      rescue StandardError => e
        raise e if is_db_connection_error?(e)

        report_exception(e)
      end
    end
  end
end
