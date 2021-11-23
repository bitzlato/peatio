# frozen_string_literal: true

module OrderServices
  class CreateSwapOrder
    include ServiceBase

    def initialize(member:)
      @member = member
    end

    def perform(market:, side:, volume:, price:)
      params = {
        market: market, side: side, price: price, volume: volume
      }

      return failure(errors: ['market.swap_order.outdated_price']) unless market.valid_swap_price?(price)

      swap_order = nil
      create_order_result = nil

      ActiveRecord::Base.transaction do
        swap_order = SwapOrder.create!(params.merge(member: @member, state: SwapOrder::STATES[:pending]))
        create_order_result = CreateOrder.new(member: @member).perform(params.merge(ord_type: 'limit'))

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
