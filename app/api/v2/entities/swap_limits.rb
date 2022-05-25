# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapLimits < Base
        expose(
          :order_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Per order Limit in USD.'
          }
        )

        expose(
          :daily_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Daily order Limit in USD.'
          }
        )

        expose(
          :weekly_limit,
          documentation: {
            type: BigDecimal,
            desc: 'Weekly order Limit in USD.'
          }
        )

        private

        def order_limit
          object['order_limit']
        end

        def daily_limit
          object['daily_limit']
        end

        def weekly_limit
          object['weekly_limit']
        end
      end
    end
  end
end
