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

        Withdrawer.new(@logger).call withdraw

        # Пока не понимаю что проихсодит с исключениями не указанными тут, поэтому отключил
        # rescue AASM::InvalidTransition => err
      rescue => err
        @logger.error id: payload[:id], message: err.message
        report_exception err, true, payload
        nil
      end
    end
  end
end
