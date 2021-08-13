module OrderServices
  class SubmitOrder
    def initialize(order)
      @order = order
    end

    def perform
      return trigger_third_party_creation unless order.market.engine.peatio_engine?
      trigger_private_event

      EventAPI.notify(
        ['market', order.market_id, 'order_created'].join('.'),
        Serializers::EventAPI::OrderCreated.call(order),
      ) if order.is_limit_order?

      AMQP::Queue.enqueue(:order_processor,
                          { action: 'submit', order: order.attributes },
                          { persistent: true })
    end

    def trigger_third_party_creation
      AMQP::Queue.publish(
        @order.market.engine.driver,
        data: @order.as_json_for_third_party,
        type: ::Order::THIRD_PARTY_ORDER_ACTION_TYPE[:submit_single]
      )
    end

    def trigger_private_event
      # skip market type orders, they should not appear on trading-ui
      return unless @order.ord_type == 'limit' || @order.state == 'done'

      ::AMQP::Queue.enqueue_event(
        'private',
        @order.member.uid,
        'order',
        @order.for_notify
      )
    end
  end
end
