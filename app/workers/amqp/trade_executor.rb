# frozen_string_literal: true

module Workers
  module AMQP
    class TradeExecutor < Base
      def initialize(market = nil)
        @market = market # Setupt but not used
        super()
      end

      def process(payload)
        # TODO: compare payload market
        ::Matching::Executor.new(payload.symbolize_keys).process
      end
    end
  end
end
