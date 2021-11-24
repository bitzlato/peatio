# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapOrder < Base
        expose(
          :id,
          documentation: {
            type: Integer,
            desc: 'Unique order id.'
          }
        )

        expose(
          :price,
          documentation: {
            type: BigDecimal,
            desc: 'Price for each unit. e.g.'\
                  "If you want to sell/buy 1 btc at 3000 usd, the price is '3000.0'"
          }
        )

        expose(
          :state,
          documentation: {
            type: String,
            desc: "One of 'wait', 'done', or 'cancel'."\
                  "An swap order in 'wait' is an active order, waiting fulfillment;"\
                  "a 'done' swap order is an swap order fulfilled;"\
                  "'cancel' means the swap order has been canceled."
          }
        )

        expose(
          :market_id,
          as: :market,
          documentation: {
            type: String,
            desc: "The market in which the order is placed, e.g. 'btcusd'."\
                  'All available markets can be found at /api/v2/markets.'
          }
        )

        expose(
          :created_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'Order create time in iso8601 format.'
          }
        )

        expose(
          :updated_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'Order updated time in iso8601 format.'
          }
        )

        expose(
          :volume,
          as: :remaining_volume,
          documentation: {
            type: BigDecimal,
            desc: "The remaining volume, see 'volume'."
          }
        )
      end
    end
  end
end
