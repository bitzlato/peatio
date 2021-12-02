# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapPrice < Base
        expose(
          :request_price,
          as: :price,
          documentation: {
            type: BigDecimal,
            desc: 'Price'
          }
        )

        expose(
          :inverse_price,
          documentation: {
            type: BigDecimal,
            desc: 'Reverse price.'
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
          :inverse_volume,
          documentation: {
            type: BigDecimal,
            desc: 'Inversevolume.'
          }
        )
      end
    end
  end
end
