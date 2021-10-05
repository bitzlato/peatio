# frozen_string_literal: true

module OrderServices
  class CreateOrder
    include ServiceBase

    POSSIBLE_SIDE_VALUES = %i[sell buy].freeze

    def initialize(member:)
      @member = member
    end

    ##
    # Creates an order and sumbits it
    #
    # @param side     [String|Symbol] possible values: "sell", "buy"
    # @param ord_type [String]        possible values: "limit", "market"
    #
    # @return [Order] if success or [nil] if failed

    def perform(
      market:,
      side:,
      ord_type:,
      volume:,
      price: nil,
      uuid: UUID.generate
    )
      order = create_order(
        market: market,
        side: side,
        ord_type: ord_type,
        price: price.to_d,
        volume: volume.to_d,
        uuid: uuid
      )
      order = submit_and_return_order(order)
      success(data: order)
    rescue ::Order::InsufficientMarketLiquidity => e
      trigger_amqp_and_failure(
        error_message: 'market.order.insufficient_market_liquidity',
        uuid: uuid
      )
    rescue ::Account::AccountError => e
      trigger_amqp_and_failure(
        error_message: 'market.account.insufficient_balance',
        uuid: uuid
      )
    rescue ActiveRecord::RecordInvalid => e
      trigger_amqp_and_failure(
        error_message: 'market.order.invalid_volume_or_price',
        uuid: uuid
      )
    rescue StandardError => e
      report_exception(e, true)
      trigger_amqp_and_failure(
        error_message: e.message,
        uuid: uuid
      )
    end

    private

    def amqp_event_payload_with_uuid(uuid:, payload:)
      {
        uuid: uuid,
        payload: payload
      }
    end

    def trigger_amqp_and_failure(error_message:, uuid:)
      ::AMQP::Queue.enqueue_event(
        'private',
        @member.uid,
        'order_error',
        amqp_event_payload_with_uuid(
          uuid: uuid,
          payload: error_message
        )
      )
      failure(errors: [error_message])
    end

    def create_order(market:, side:, ord_type:, price:, volume:, uuid:)
      symbolized_side = symbolize_and_check_side!(side)

      member_account = get_member_account(side: symbolized_side, market: market)
      # Single Order can produce multiple Trades
      # with different fee types (maker and taker).
      # Since we can't predict fee types on order creation step and
      # Market fees configuration can change we need
      # to store fees on Order creation.
      trading_fee = TradingFee.for(
        group: @member.group,
        market_id: market.symbol,
        market_type: ::Market::DEFAULT_TYPE
      )
      maker_fee = trading_fee.maker
      taker_fee = trading_fee.taker
      locked_value, order_subclass = nil
      price = nil if ord_type == 'market'

      member_account.with_lock do
        if symbolized_side == :sell
          order_subclass = OrderAsk
          locked_value = calc_sell_compute_locked(
            ord_type: ord_type,
            volume: volume,
            market: market
          )
        else
          order_subclass = OrderBid
          locked_value = calc_buy_compute_locked(
            ord_type: ord_type,
            price: price,
            volume: volume,
            market: market,
            member_balance: member_account.balance
          )
        end
      end

      order_subclass.create!(
        state: ::Order::PENDING,
        member: @member,
        ask: market.base_unit,
        bid: market.quote_unit,
        market: market,
        market_type: ::Market::DEFAULT_TYPE,
        ord_type: ord_type || 'limit',
        price: price,
        volume: volume,
        origin_volume: volume,
        locked: locked_value,
        origin_locked: locked_value,
        uuid: uuid,
        maker_fee: maker_fee,
        taker_fee: taker_fee
      )
    end

    # OrderAsk
    def calc_sell_compute_locked(ord_type:, volume:, market:)
      case ord_type
      when 'limit'
        volume
      when 'market'
        estimate_required_funds(
          price_levels: OrderBid.get_depth(market.symbol),
          volume: volume
        ) { |_, value| value }
      end
    end

    # OrderBid
    def calc_buy_compute_locked(ord_type:, price:, volume:, market:, member_balance:)
      value = case ord_type
              when 'limit'
                price * volume
              when 'market'
                funds = estimate_required_funds(
                  price_levels: OrderAsk.get_depth(market.symbol),
                  volume: volume
                ) { |price, volume| price * volume }
                # Maximum funds precision defined in Market::FUNDS_PRECISION.
                funds.round(Market::FUNDS_PRECISION, BigDecimal::ROUND_UP)
              end
      [
        value * OrderBid::LOCKING_BUFFER_FACTOR,
        member_balance
      ].min
    end

    def get_member_account(side:, market:)
      currency_unit = side == :sell ? market.base_unit : market.quote_unit
      currency = Currency.find(currency_unit)
      @member.get_account(currency)
    end

    def estimate_required_funds(price_levels:, volume:)
      required_funds = Account::ZERO
      expected_volume = volume

      until expected_volume.zero? || price_levels.empty?
        level_price, level_volume = price_levels.shift

        actual_volume = [expected_volume, level_volume].min
        required_funds += yield level_price, actual_volume
        expected_volume -= actual_volume
      end

      if expected_volume.nonzero?
        raise(
          ::Order::InsufficientMarketLiquidity,
          "Insufficient market liquidity for volume = #{volume}"
        )
      end

      required_funds
    end

    def submit_and_return_order(order)
      if order.market.engine.peatio_engine?
        if order.is_limit_order?
          EventAPI.notify(
            ['market', order.market_id, 'order_created'].join('.'),
            Serializers::EventAPI::OrderCreated.call(order)
          )
        end

        AMQP::Queue.enqueue(:order_processor,
                            { action: 'submit', order: order.attributes },
                            { persistent: true })
      else
        order.trigger_third_party_creation
      end

      order
    end

    def symbolize_and_check_side!(side)
      symbol = side.to_sym

      unless POSSIBLE_SIDE_VALUES.include?(symbol)
        raise(
          IncorrectSideValue,
          "side = #{symbol}. Possible side values: #{POSSIBLE_SIDE_VALUES.join(' or ')}"
        )
      end

      symbol
    end

    class IncorrectSideValue < StandardError; end
  end
end
