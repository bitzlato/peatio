# frozen_string_literal: true

module Workers
  module Daemons
    class StaleOrderCancellator < Base
      @sleep_time = 1.minute

      def process
        Order.where(state: :wait).where.not(canceling_at: nil).where('canceling_at < ?', 1.minute.ago).find_each do |order|
          order.trigger_cancellation(force: true)
          Rails.logger.error({ message: 'Stale order is canceled', order_id: order.id })
        end
      end
    end
  end
end
