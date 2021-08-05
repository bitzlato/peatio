module Workers
  module AMQP
    class AccountNotifier < Base
      def process(payload)
        process_method = "process_originating_from_#{payload['origin']}"

        if self.respond_to? process_method
          send process_method, payload
        else
          report_unsupported_origin payload
        end
      rescue StandardError => e
        # ::AMQP::Queue.enqueue(:account_notifier_error, e.message)
        report_exception_to_screen(e)

        raise e if is_db_connection_error?(e)
      end

      private

      def process_originating_from_order_processor(payload)
        order_id = payload['order_id']
        order_id ||= payload.dig('order', 'id')

        case payload['action']
        when 'submit'
          account_enqueue_by_order order_id
        when 'cancel'
          account_enqueue_by_order order_id
        end
      end

      def process_originating_from_trade_executor(payload)
        order_id = payload['order_id']
        order_id ||= payload.dig('order', 'id')

        case payload['event']
        when 'order_canceled'
          account_enqueue_by_order order_id
        when 'order_completed'
          account_enqueue_by_order order_id
          account_enqueue_by_order order_id, income_currency_side: true
        when 'order_updated'
          account_enqueue_by_order order_id
          account_enqueue_by_order order_id, income_currency_side: true
        else
        end
      end

      def account_enqueue_by_order(order_id, income_currency_side: false)
        order = Order.find_by_id order_id
        account = Account.find_by(
          currency_id: order.send(
            income_currency_side ? :income_currency : :outcome_currency
          ).id,
          member_id: order.member_id
        )

        AMQP::Queue.enqueue_event(
          "private",
          order.member.uid,
          'account',
          account
        )
      end

      def report_unsupported_origin(payload)
        Rails.logger.info do
          "Origin is not supported by account_notifier. Payload #{payload.inspect}"
        end
      end
    end
  end
end
