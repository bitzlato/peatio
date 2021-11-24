# frozen_string_literal: true

module OrderServices
  class CreateSwapOrder
    include ServiceBase

    def initialize(member:)
      @member = member
    end

    def perform(from_currency:, to_currency:, price:, volume:)
      market = Market.spot.find_by_currencies(from_currency.id, to_currency.id)
      return failure(errors: ['market.swap_order.invalid_market']) unless market

      # convert price to base currency and validate with current swap price
      reference_price = market.swap_price
      verifiable_price = market.price_in(price, from_currency.id)
      return failure(errors: ['market.swap_order.outdated_price']) unless market.valid_swap_price?(verifiable_price, reference_price)

      # set order price as current swap price(reference_price)
      order_price = reference_price
      if market.base == from_currency
        order_side = 'sell'
        order_volume = volume
      else
        order_side = 'buy'
        # convert volume to base currency
        order_volume = market.round_amount((volume / order_price).to_d)
      end

      swap_order = nil
      create_order_result = nil

      ActiveRecord::Base.transaction do
        swap_order = SwapOrder.create!(
          market: market,
          member: @member,
          state: SwapOrder::STATES[:wait],
          from_currency: from_currency,
          to_currency: to_currency,
          price: price,
          volume: volume
        )

        create_order_result = CreateOrder.new(member: @member).perform(
          market: market,
          side: order_side,
          price: order_price,
          volume: order_volume,
          ord_type: 'limit'
        )

        swap_order.update!(order: create_order_result.data)

        raise ActiveRecord::Rollback if create_order_result.failed?
      end

      if create_order_result.successful?
        success(data: swap_order)
      else
        failure(errors: create_order_result.errors)
      end
    rescue ActiveRecord::RecordInvalid => _e
      failure(errors: ['market.swap_order.invalid_volume_or_price'])
    rescue StandardError => e
      report_exception(e, true)
      failure(errors: [e.message])
    end
  end
end
