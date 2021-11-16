# frozen_string_literal: true

module Workers
  module AMQP
    class DepositIntention < Base
      def process(payload)
        payload.symbolize_keys!

        deposit = Deposit.find_by_id(payload[:deposit_id])
        unless deposit
          Rails.logger.warn do
            { message: 'Deposit intention does not exists',
              deposit_id: payload[:deposit_id],
              serivce: :deposit_intention }
          end
          return
        end

        Rails.logger.info do
          { message: 'Create invoice', deposit_id: deposit.id, serivce: :deposit_intention }
        end

        deposit.blockchain.gateway.create_invoice! deposit

        # Repeat again
      rescue Bitzlato::Client::WrongResponse => e
        Rails.logger.error do
          { message: e.messaage, deposit_id: payload[:deposit_id], service: :deposit_intention }
        end
        report_exception(e)
        raise e
      rescue StandardError => e
        Rails.logger.error do
          { message: e.messaage, deposit_id: payload[:deposit_id], service: :deposit_intention }
        end
        raise e if is_db_connection_error?(e)

        report_exception(e)
      end
    end
  end
end
