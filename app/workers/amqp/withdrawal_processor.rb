# frozen_string_literal: true

module Workers
  module AMQP
    class WithdrawalProcessor < Base
      def process(payload)
        payload.symbolize_keys!

        withdrawal = Withdraw.find(payload[:remote_id])
        witdraw.with_lock do
          Rails.logger.info { { message: 'Withdrawal is processed', payload: payload.inspect } }

          if withdrawal.processing?
            withdrawal.transfer!
            begin
              raise Busy, 'The withdrawal is being processed by another worker or has already been processed.' unless withdrawal.transfering?
              raise Fail, 'The destination address doesn\'t exist.' if withdrawal.rid.blank?

              withdrawal.update!(txid: payload[:txid])
              withdrawal.dispatch!
              Rails.logger.info { { message: 'Withdrawal is dispatched', payload: payload.inspect } }
            rescue Busy, Fail => e
              # TODO: repeat withdrawal for Busy
              withdrawal.fail!
              Rails.logger.warn { e.as_json.merge(id: withdrawal.id) }
            end
          end
          if withdrawal.confirming?
            if payload[:status] == 'failed'
              withdrawal.fail!
              Rails.logger.info { { message: 'Withdrawal is failed', payload: payload.inspect } }
            elsif payload[:status] == 'success' && payload[:confirmations].to_i >= withdrawal.blockchain.min_confirmations
              withdrawal.success!
              Rails.logger.info { { message: 'Withdrawal is successed', payload: payload.inspect } }
            end
          end
        rescue StandardError => e
          Rails.logger.warn id: withdrawal.id, message: 'Setting withdrawal state to errored.'
          report_exception e, true, withdrawal_id: withdrawal.id
          withdrawal.err! e

          raise e if is_db_connection_error?(e)
        end
      end
    end
  end
end
