module OrderServices
  class CreateOrder
    def initialize(member)
      @member = member
    end

    def perform(market:, side:, ord_type:, price:, volume:)
      @market = ::Market.active.find_spot_by_symbol(market)

      order = build_order(
        market: @market,
        side: side,
        ord_type: ord_type,
        price: price,
        volume: volume,
      )
      submit_order!(order)

      order.reload
    end

    private

    def build_order(side:, ord_type:, price:, volume:)
      order_subclass = side == 'sell' ? OrderAsk : OrderBid

      order_subclass.new(
        state:         ::Order::PENDING,
        member:        @member,
        ask:           @market&.base_unit,
        bid:           @market&.quote_unit,
        market:        @market,
        market_type:   ::Market::DEFAULT_TYPE,
        ord_type:      ord_type || 'limit',
        price:         price,
        volume:        volume,
        origin_volume: volume,
      )
    end

    def submit_order!(order)
      return unless order.new_record?

      order.locked = order.origin_locked = if order.ord_type == 'market' && order.side == 'buy'
                                             [
                                               order.compute_locked * OrderBid::LOCKING_BUFFER_FACTOR,
                                               order.ember_balance
                                             ].min
                                           else
                                             order.compute_locked
                                           end

      raise(
        ::Account::AccountError,
        "member_balance > locked = #{order.member_balance}>#{order.locked}"
      ) unless order.member_balance >= order.locked

      return order.trigger_third_party_creation unless order.market.engine.peatio_engine?

      order.save!
      AMQP::Queue.enqueue(:order_processor,
                          { action: 'submit', order: order.attributes },
                          { persistent: false })
    end
  end
end
