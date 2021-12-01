# frozen_string_literal: true

module Workers
  module Daemons
    class SwapOrderStatusChecker < Base
      @sleep_time = 10

      def process
        swap_orders = SwapOrder.open.includes(:order)

        swap_orders.find_each do |swap_order|
          state = get_state_for!(swap_order)
          swap_order.update!(state: state)
        end
      end

      private

      def get_state_for!(swap_order)
        case swap_order.order.state
        when 'cancel', 'reject'
          'cancel'
        when 'done'
          'done'
        when 'pending', 'wait'
          'wait'
        else
          raise "Unsupported order state: #{order.state}"
        end
      end
    end
  end
end
