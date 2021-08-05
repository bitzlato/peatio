# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class OrderProcessor < Base
      def initialize
        Order.spot.where(state: ::Order::PENDING).find_each do |order|
          Order.submit(order.id)
        rescue StandardError => e
          ::AMQP::Queue.enqueue(:trade_error, e.message)
          report_exception_to_screen(e)

          raise e if is_db_connection_error?(e)
        end
      end

      def process(payload)
        order_id = payload.dig('order', 'id')

        case payload['action']
        when 'submit'
          order = Order.submit order_id
        when 'cancel'
          order = Order.cancel order_id
        end

        ::AMQP::Queue.enqueue(
          :account_notifier,
          action: payload['action'],
          origin: "order_processor",
          order_id: order_id
        )
      rescue StandardError => e
        ::AMQP::Queue.enqueue(:trade_error, e.message)
        report_exception_to_screen(e)

        raise e if is_db_connection_error?(e)
      end
    end
  end
end
