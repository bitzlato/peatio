# frozen_string_literal: true

module Workers
  module Daemons
    class Ticker < Base
      @sleep_time = 5

      def process
        @tickers = {}
        @cache_tickers = {}
        Market.spot.active.each do |market|
          service = TickersService[market]
          ticker = service.ticker
          @tickers[market.symbol] = ticker
          @cache_tickers[market.symbol] = format_ticker ticker
        end
        Rails.logger.info { "Publish tickers: #{@tickers}" }
        Rails.cache.write(:markets_tickers, @cache_tickers)
        ::AMQP::Queue.enqueue_event('public', 'global', 'tickers', @tickers)
      end

      def format_ticker(ticker)
        { at: ticker[:at],
          ticker: ticker }
      end
    end
  end
end
