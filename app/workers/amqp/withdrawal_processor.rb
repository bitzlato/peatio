# frozen_string_literal: true

module Workers
  module AMQP
    class WithdrawalProcessor < Base
      def process(payload)
        payload.symbolize_keys!

        withdrawal = Withdraw.find(payload[:remote_id])
        withdrawal.with_lock do
          Rails.logger.info { { message: 'Withdrawal is processed', payload: payload.inspect } }

          case payload[:status]
          when 'confirming'
            raise 'Incorrect withdrawal event' if payload[:owner_id].split(':').last != withdrawal.member.uid

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
          when 'succeed'
            raise 'Incorrect withdrawal event' if payload[:owner_id].split(':').last != withdrawal.member.uid || payload[:currency] != withdrawal.currency_id || payload[:amount].to_d != withdrawal.amount || payload[:blockchain_key] != withdrawal.blockchain.key

            withdrawal.success!
            Rails.logger.info { { message: 'Withdrawal is successed', payload: payload.inspect } }
          when 'failed'
            withdrawal.fail!
            Rails.logger.info { { message: 'Withdrawal is failed', payload: payload.inspect } }
          when 'errored'
            raise 'Errored withdrawal status'
          else
            raise 'Unsupported withdrawal status'
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
