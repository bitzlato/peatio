module OrderServices
  class CreateOrder
    def initialize(member_id, params)
      @params = params
      @user = Member.find(member_id)
      @market = ::Market.active.find_spot_by_symbol(@params[:market])
    end

    def perform
      order = build_order
      order.submit_order
      order
    end

    private

    def build_order
      order_subclass = @params[:side] == 'sell' ? OrderAsk : OrderBid
      order_subclass.new(
        state:         ::Order::PENDING,
        member:        @user,
        ask:           @market&.base_unit,
        bid:           @market&.quote_unit,
        market:        @market,
        market_type:   ::Market::DEFAULT_TYPE,
        ord_type:      @params[:ord_type] || 'limit',
        price:         @params[:price],
        volume:        @params[:volume],
        origin_volume: @params[:volume]
      )
    end
  end
end
