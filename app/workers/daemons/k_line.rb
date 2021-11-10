# frozen_string_literal: true

module Workers
  module Daemons
    class KLine < Base
      @sleep_time = 2

      def process
        Market.active.each do |market|
          ::KLineService::AVAILABLE_POINT_PERIODS.each do |period|
            service = ::KLineService[market.symbol, period]
            point = service.get_ohlc(order_by: :desc, limit: 1, offset: false).first
            next if point.blank?

            event_name = service.event_name(period)
            Rails.logger.info { "publishing #{point} #{event_name} stream for #{market.symbol}" }
            ::AMQP::Queue.enqueue_event('public', market.symbol,
                                        event_name, point)
          end
        end
      end
    end
  end
end
