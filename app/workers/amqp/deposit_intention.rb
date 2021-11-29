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
        gateway = deposit.blockchain.gateway

        if gateway.respond_to? :create_invoice!
          gateway.create_invoice! deposit
        else
          deposit.with_lock do
            Rails.logger.info do
              { message: 'Reject deposit intention (no create_invoice! method in gateway)', deposit_id: deposit.id, serivce: :deposit_intention }
            end
            deposit.reject!
            report_exception('Reject deposit intention (no create_invoice! method in gateway)', true, payload)
          end
        end

        # Repeat again
      rescue Bitzlato::Client::WrongResponse => e
        Rails.logger.error do
          { message: e.message, deposit_id: payload[:deposit_id], service: :deposit_intention }
        end
        report_exception(e, true, payload)
        raise e
      rescue StandardError => e
        Rails.logger.error do
          { message: e.message, deposit_id: payload[:deposit_id], service: :deposit_intention }
        end
        raise e if is_db_connection_error?(e)

        report_exception(e, true, payload)
      end
    end
  end
end
