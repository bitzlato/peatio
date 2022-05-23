# frozen_string_literal: true

module Workers
  module AMQP
    class WithdrawCoin < Base
      def initialize
        @logger = TaggedLogger.new(Rails.logger, worker: __FILE__)
      end

      def process(payload)
        payload.symbolize_keys!

        @logger.warn id: payload[:id], message: 'Received request for processing withdraw.'

        withdraw = Withdraw.find_by_id(payload[:id])
        if withdraw.blank?
          @logger.warn id: payload[:id], message: 'The withdraw with such ID doesn\'t exist in database.'
          return
        end

        if %w[avax-mainnet heco-mainnet eth-ropsten].include?(blockchain.key)
          withdraw.transfer!

          BelomorClient.new(blockchain_key: withdraw.blockchain.key).create_withdrawal(
            to_address: withdraw.to_address,
            amount: withdraw.amount,
            currency_id: withdraw.currency_id,
            owner_id: "user:#{withdraw.member.uid}",
            remote_id: withdraw.id,
            meta: { note: withdraw.note }
          )
        else
          Withdrawer.new(@logger).call withdraw
        end

        # Пока не понимаю что проихсодит с исключениями не указанными тут, поэтому отключил
        # rescue AASM::InvalidTransition => err
      rescue StandardError => e
        @logger.error id: payload[:id], message: e.message
        report_exception e, true, payload
        nil
      end
    end
  end
end
