# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapOrder < Base
        expose(
          :id,
          documentation: {
            type: Integer,
            desc: 'Unique swap order id.'
          }
        )

        expose(
          :state,
          documentation: {
            type: String,
            values: ::SwapOrder.state.values,
            desc: "One of 'pending', 'wait', 'done', or 'cancel'."\
                  "An swap order in 'pending' is an waiting when order will be created;"\
                  "a 'wait' is an active order, waiting fulfillment;"\
                  "a 'done' swap order is an swap order fulfilled;"\
                  "'cancel' means the swap order has been canceled."
          }
        )

        expose(
          :from_currency,
          documentation: {
            type: String,
            desc: 'From currency id.'
          }
        )

        expose(
          :from_volume,
          documentation: {
            type: BigDecimal,
            desc: 'From volume.'
          }
        )

        expose(
          :to_currency,
          documentation: {
            type: String,
            desc: 'To currency id.'
          }
        )

        expose(
          :to_volume,
          documentation: {
            type: BigDecimal,
            desc: 'To volume.'
          }
        )

        expose(
          :request_currency,
          documentation: {
            type: String,
            desc: 'Request currency id.'
          }
        )

        expose(
          :request_volume,
          documentation: {
            type: BigDecimal,
            desc: 'Request volume.'
          }
        )

        expose(
          :request_price,
          documentation: {
            type: BigDecimal,
            desc: 'Request price.'
          }
        )

        expose(
          :inverse_price,
          documentation: {
            type: BigDecimal,
            desc: 'Inverse price.'
          }
        )

        expose(
          :created_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'Swap Order create time in iso8601 format.'
          }
        )

        expose(
          :updated_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'Swap Order updated time in iso8601 format.'
          }
        )
      end
    end
  end
end
