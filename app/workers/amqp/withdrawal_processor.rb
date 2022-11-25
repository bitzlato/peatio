# frozen_string_literal: true

module Workers
  module AMQP
    class WithdrawalProcessor < BelomorConsumer
      class ErroredStatusError < StandardError; end

      def process(payload)
        verify_payload!(payload)

        payload.symbolize_keys!
        withdrawal = Withdraw.find(payload[:remote_id])
        return if Withdraw::COMPLETED_STATES.include?(withdrawal.aasm_state.to_sym)

        withdrawal.with_lock do
          Rails.logger.info { { message: 'Withdrawal is processed', payload: payload.inspect } }

          case payload[:status]
          when 'confirming'
            raise IncorrectPayloadError if payload[:owner_id].split(':').last != withdrawal.member.uid

            withdrawal.process! if withdrawal.errored?
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
          when 'succeed'
            raise IncorrectPayloadError if payload[:owner_id].split(':').last != withdrawal.member.uid || payload[:currency] != withdrawal.currency_id || payload[:amount].to_d != withdrawal.amount || payload[:blockchain_key] != withdrawal.blockchain.key

            withdrawal.update!(txid: payload[:txid]) if withdrawal.processing?
            withdrawal.success!
            Rails.logger.info { { message: 'Withdrawal is successed', payload: payload.inspect } }
          when 'failed'
            withdrawal.process! if withdrawal.accepted?
            withdrawal.fail!
            Rails.logger.info { { message: 'Withdrawal is failed', payload: payload.inspect } }
          when 'errored'
            raise ErroredStatusError, 'Errored withdrawal status'
          else
            raise 'Unsupported withdrawal status'
          end
        rescue IncorrectPayloadError => e
          report_exception(e, true, payload)
        rescue StandardError => e
          Rails.logger.warn id: withdrawal.id, message: 'Setting withdrawal state to errored.'
          report_exception e, true, withdrawal_id: withdrawal.id unless e.is_a?(ErroredStatusError)
          withdrawal.process! if withdrawal.accepted?
          withdrawal.err!(e) unless withdrawal.errored?

          raise e if is_db_connection_error?(e)
        end
      rescue IncorrectPayloadError, JWT::DecodeError => e
        report_exception(e, true, payload)
      end
    end
  end
end
