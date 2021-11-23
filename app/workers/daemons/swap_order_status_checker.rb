# frozen_string_literal: true

module Workers
  module Daemons
    class SwapOrderStatusChecker < Base
      @sleep_time = 15

      def process
        SwapOrder.open.includes(:order).find_each do |swap_order|
          swap_order.update!(state: swap_order.order.state)
        end
      end
    end
  end
end
