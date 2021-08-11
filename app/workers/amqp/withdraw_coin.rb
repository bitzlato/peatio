# encoding: UTF-8
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

        wallet = withdraw.currency.blockchain.wallets.hot.with_currency(withdraw.currency).take
        if wallet.blank?
          @logger.warn id: payload[:id], message: 'No hot wallet for withdraw'
          return
        end

        Withdrawer.new(withdraw, @logger).call withdraw
      end
    end
  end
end
