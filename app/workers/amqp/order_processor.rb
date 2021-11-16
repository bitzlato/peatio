# frozen_string_literal: true

module Workers
  module AMQP
    class OrderProcessor < Base
      ACTUAL_PERIOD = Rails.env.production? ? 1.second : 10.seconds

      def initialize(market_symbol = nil)
        @market_symbol = market_symbol
        raise "Wrong market specific settings (#{market_symbol})" unless market_symbol.present? == Peatio::App.config.market_specific_workers

        Rails.logger.info { 'Resubmit orders' }
        return if ENV.true?('SKIP_SUBMIT_PENDING_ORDERS')

        orders = Order.spot.where(state: ::Order::PENDING)
        orders = orders.with_market(market_symbol) if market_symbol.present?
        orders.find_each do |order|
          submit_order(order.id)
        rescue StandardError => e
          ::AMQP::Queue.enqueue(:trade_error, e.message)
          report_exception e, true, order: order.as_json

          raise e if is_db_connection_error?(e)
        end
        Rails.logger.info { 'Orders are resubmited' }
      end

      def process(payload)
        case payload['action']
        when 'submit'
          raise "Wrong market '#{@market_symbol}' for #{payload}" if @market_symbol.present? && payload.dig('order', 'market_id') != @market_symbol

          submit_order(payload.dig('order', 'id'))
        when 'cancel'
          raise "Wrong market '#{@market_symbol}' for #{payload}" if @market_symbol.present? && payload.dig('order', 'market') != @market_symbol

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

          if order.created_at < ACTUAL_PERIOD.ago
            Rails.logger.warn { "Order is too old #{order.id} #{order.created_at} (#{Time.zone.now - order.created_at} secs old) reject it" }
            reject_order id
            return
          end

          order.hold_account!.lock_funds!(order.locked)
          order.record_submit_operations!
          order.update!(state: ::Order::WAIT)

          ::AMQP::Queue.enqueue(:matching,
                                { action: 'submit', order: order.to_matching_attributes },
                                {},
                                Peatio::App.config.market_specific_workers ? order.market_id : nil)
        end
      rescue StandardError => e
        report_exception e, true, order_id: id
        reject_order_in_transaction id

        raise e
      end

      def reject_order_in_transaction(id)
        ActiveRecord::Base.transaction do
          Rails.logger.info { "Reject order #{id}" }
          order = Order.lock.find(id)
          if order.state == ::Order::PENDING
            order&.update!(state: ::Order::REJECT)
          else
            report_exception 'Wrong order status when reject', true, order_id: id, order: order
          end
        end
      end

      def reject_order(id)
        Rails.logger.info { "Reject order #{id}" }
        order = Order.find(id)
        order&.update!(state: ::Order::REJECT)
      end

      def cancel_order(id)
        ActiveRecord::Base.transaction do
          order = Order.lock.find(id)
          if order.state == ::Order::PENDING
            Rails.logger.warn { "Reject pending order #{id}" }
            reject_order id
            return
          end
          return unless order.state == ::Order::WAIT

          market_engine = order.market.engine
          return order.trigger_third_party_cancellation unless market_engine.peatio_engine?

          order.hold_account!.unlock_funds!(order.locked)
          order.record_cancel_operations!

          order.update!(state: ::Order::CANCEL)
        end
      end
    end
  end
end
