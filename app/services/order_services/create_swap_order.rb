# frozen_string_literal: true

module OrderServices
  class CreateSwapOrder
    include ServiceBase

    def initialize(member:)
      @member = member
    end

    def perform(market:, side:, volume:, price:, uuid: UUID.generate)
      params = {
        market: market, side: side, price: price, volume: volume, uuid: uuid
      }

      swap_order = SwapOrder.create!(params.merge(member: @member, state: SwapOrder::STATES[:pending]))
      create_order_result = CreateOrder.new(member: @member).perform(params.merge(ord_type: 'limit'))

      if create_order_result.data
        success(data: swap_order)
      else
        failure(errors: create_order_result.errors)
      end
    rescue ActiveRecord::RecordInvalid => _e
      failure(errors: ['market.swap.invalid_volume_or_price'])
    rescue StandardError => e
      report_exception(e, true)
      failure(errors: [e.message])
    end
  end
end
