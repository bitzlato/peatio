# frozen_string_literal: true

module OrderServices
  class CreateSwapOrder
    include ServiceBase

    def initialize(member:)
      @member = member
    end

    def perform(from_currency:, to_currency:, price:, volume:)
      swap_price_service = CurrencyServices::SwapPrice.new(from_currency: from_currency, to_currency: to_currency)

      return failure(errors: ['market.swap_order.invalid_market']) unless swap_price_service.market?
      return failure(errors: ['market.swap_order.outdated_price']) unless swap_price_service.valid_price?(price)

      unified_currency = swap_price_service.unified_currency
      return failure(errors: ['market.swap_order.no_unified_currency']) unless unified_currency

      unified_price = swap_price_service.unified_price
      return failure(errors: ['market.swap_order.no_unified_price']) unless unified_price

      unified_total_amount = volume * unified_price

      return failure(errors: ['market.swap_order.reached_weekly_limit']) if (unified_total_amount + SwapOrder.weekly_unified_total_amount_for(@member)) > config['weekly_limit']
      return failure(errors: ['market.swap_order.reached_daily_limit']) if (unified_total_amount + SwapOrder.daily_unified_total_amount_for(@member)) > config['daily_limit']

      order_volume = swap_price_service.conver_amount_to_base(volume)

      swap_order = nil
      create_order_result = nil

      swap_order = SwapOrder.create!(
        market: swap_price_service.market,
        member: @member,
        state: SwapOrder::STATES[:pending],
        from_currency: from_currency,
        to_currency: to_currency,
        price: swap_price_service.request_price,
        volume: volume,
        unified_price: unified_price,
        unified_total_amount: unified_total_amount,
        unified_currency: unified_currency
      )

      create_order_result = CreateOrder.new(member: @member).perform(
        market: swap_price_service.market,
        side: swap_price_service.side,
        price: swap_price_service.price,
        volume: order_volume,
        ord_type: 'limit'
      )

      if create_order_result.successful?
        swap_order.update!(order: create_order_result.data, state: SwapOrder::STATES[:wait])
        success(data: swap_order)
      else
        swap_order.update!(state: SwapOrder::STATES[:cancel])
        failure(errors: create_order_result.errors)
      end
    rescue ActiveRecord::RecordInvalid => _e
      failure(errors: ['market.swap_order.invalid_volume_or_price'])
    rescue StandardError => e
      report_exception(e, true)
      failure(errors: [e.message])
    end

    private

    def config
      Rails.application.config_for(:swap)
    end
  end
end
