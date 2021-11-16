# frozen_string_literal: true

module Workers
  module AMQP
    class OrderCancellator < OrderProcessor
      def initialize # rubocop:disable Lint/MissingSuper
        Rails.logger.info 'Start order cancellator'
      end

      def process(payload)
        cancel_order(payload.dig('order', 'id'))
      rescue StandardError => e
        ::AMQP::Queue.enqueue(:trade_error, e.message)
        report_exception e, true, payload: payload

        raise e if is_db_connection_error?(e)
      end
    end
  end
end
