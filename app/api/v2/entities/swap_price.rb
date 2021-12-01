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
      end
    end
  end
end
