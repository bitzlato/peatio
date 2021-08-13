module OrderServices
  class CreateOrder
    def initialize(member)
      @member = member
    end

    def perform(market:, side:, ord_type:, price:, volume:)
      order = build_order(
        market: market,
        side: side,
        ord_type: ord_type,
        price: price,
        volume: volume,
      )
      submit_order!(order)

      order.reload!
    end

    private

    def build_order(market:,side:, ord_type:, price:, volume:)
      order_subclass = side == 'sell' ? OrderAsk : OrderBid
      uuid = UUID.generate

      # Single Order can produce multiple Trades
      # with different fee types (maker and taker).
      # Since we can't predict fee types on order creation step and
      # Market fees configuration can change we need
      # to store fees on Order creation.
      trading_fee = TradingFee.for(
        group: member.group,
        market_id: market.id,
        market_type: ::Market::DEFAULT_TYPE
      )
      maker_fee = trading_fee.maker
      taker_fee = trading_fee.taker

      order = order_subclass.new(
        state:         ::Order::PENDING,
        member:        @member,
        ask:           market.base_unit,
        bid:           market.quote_unit,
        market:        market,
        market_type:   ::Market::DEFAULT_TYPE,
        ord_type:      ord_type || 'limit',
        price:         price,
        volume:        volume,
        origin_volume: volume,
        locked:        locked_value,
        origin_locked: locked_value,
        uuid:          uuid,
        maker_fee:     maker_fee,
        taker_fee:     taker_fee,
      )

      locked_value = if order.ord_type == 'market' && order.side == 'buy'
        [
          order.compute_locked * OrderBid::LOCKING_BUFFER_FACTOR,
          order.member_balance
        ].min
      else
        order.compute_locked
      end

      order.assign_attributes(
        locked: locked_value,
        origin_locked: locked_value
      )

      order.save!

      raise(
        ::Account::AccountError,
        "member_balance > locked = #{order.member_balance} > #{order.locked}"
      ) if order.member_balance < order.locked

      order
    end

    def submit_order!(order)
      return order.trigger_third_party_creation unless order.market.engine.peatio_engine?
      order.trigger_private_event

      EventAPI.notify(
        ['market', order.market_id, 'order_created'].join('.'),
        Serializers::EventAPI::OrderCreated.call(order),
      ) if order.is_limit_order?

      AMQP::Queue.enqueue(:order_processor,
                          { action: 'submit', order: order.attributes },
                          { persistent: true })
    end
  end
end
