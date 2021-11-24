# frozen_string_literal: true

module Workers
  module Daemons
    class SwapOrderStatusChecker < Base
      @sleep_time = 15

      def process
        SwapOrder.open.includes(:order).find_each do |swap_order|
          order = swap_order.order
          state = case order.state
                  when 'cancel', 'reject'
                    'cancel'
                  when 'done'
                    'done'
                  when 'pending', 'wait'
                    'wait'
                  else
                    raise "Unsupported order state: #{order.state}"
                  end

          swap_order.update!(state: state)
        end
      end
    end
  end
end
