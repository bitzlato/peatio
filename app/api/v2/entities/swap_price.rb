# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapPrice < Base
        expose(
          :price,
          documentation: {
            type: BigDecimal,
            desc: 'Swap price.'
          }
        )
      end
    end
  end
end
