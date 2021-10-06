# frozen_string_literal: true

module Workers
  module AMQP
    class OrderProcessor < Base
      def initialize
        if ENV.true?('LOAD_PENDING_ORDERS_ON_START')
          Rails.logger.info('Resubmit orders')
          Order.spot.where(state: ::Order::PENDING).find_each do |order|
            Order.submit(order.id)
          rescue StandardError => e
            ::AMQP::Queue.enqueue(:trade_error, e.message)
            report_exception e, true, order: order.as_json

            raise e if is_db_connection_error?(e)
          end
          Rails.logger.info('Orders are resubmited')
        end
      end

      def process(payload)
        case payload['action']
        when 'submit'
          Order.submit(payload.dig('order', 'id')) unless ENV.true?('IGNORE_SUBMIT_ORDERS')
        when 'cancel'
          Order.cancel(payload.dig('order', 'id'))
        end
      rescue StandardError => e
        ::AMQP::Queue.enqueue(:trade_error, e.message)
        report_exception e, true, payload: payload

        raise e if is_db_connection_error?(e)
      end
    end
  end
end
