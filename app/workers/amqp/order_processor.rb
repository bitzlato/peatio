# frozen_string_literal: true

module Workers
  module AMQP
    class OrderProcessor < Base
      def initialize
        Rails.logger.info('Resubmit orders')
        return if ENV.true?('SKIP_SUBMIT_PENDING_ORDERS')
        Order.spot.where(state: ::Order::PENDING).find_each do |order|
          submit_order(order.id)
        rescue StandardError => e
          ::AMQP::Queue.enqueue(:trade_error, e.message)
          report_exception e, true, order: order.as_json

          raise e if is_db_connection_error?(e)
        end
        Rails.logger.info('Orders are resubmited')
      end

      def process(payload)
        case payload['action']
        when 'submit'
          submit_order(payload.dig('order', 'id'))
        when 'cancel'
          cancel_order(payload.dig('order', 'id'))
        end
      rescue StandardError => e
        ::AMQP::Queue.enqueue(:trade_error, e.message)
        report_exception e, true, payload: payload

        raise e if is_db_connection_error?(e)
      end

      private

      def submit_order(id)
        ActiveRecord::Base.transaction do
          order = Order.lock.find(id)
          return unless order.state == ::Order::PENDING

          order.hold_account!.lock_funds!(order.locked)
          order.record_submit_operations!
          order.update!(state: ::Order::WAIT)

          ::AMQP::Queue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
        end
      rescue StandardError => e
        report_exception e, true, order_id: id

        reject_order id

        raise e
      end

      def reject_order(id)
        order = Order.find(id)
        order&.update!(state: ::Order::REJECT)
      rescue StandardError => e
        Bugsnag.notify e do |b|
          b.meta_data = { order_id: id }
        end
      end

      def cancel_order(id)
        order = Order.lock.find(id)
        return unless order.state == ::Order::WAIT

        market_engine = order.market.engine
        return order.trigger_third_party_cancellation unless market_engine.peatio_engine?

        ActiveRecord::Base.transaction do
          order.hold_account!.unlock_funds!(order.locked)
          order.record_cancel_operations!

          order.update!(state: ::Order::CANCEL)
        end
      end
    end
  end
end
