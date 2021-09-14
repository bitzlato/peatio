# frozen_string_literal: true

require 'peatio/influxdb'
class TickersService
  ZERO = '0.0'.to_d

  class << self
    def [](market)
      services[market] ||= new(market)
    end

    def services
      @services ||= {}
    end
  end

  attr_accessor :market_symbol

  def initialize(market)
    @market_symbol = if market.is_a? Market
                       market.symbol
                     else
                       market.to_s
                     end
  end

  def ticker
    ticker = Trade.market_ticker_from_influx(market_symbol)
    format(ticker)
  end

  def default_ticker
    { min: ZERO, max: ZERO, last: ZERO, first: ZERO, volume: ZERO, amount: ZERO, vwap: ZERO }
  end

  def format(ticker)
    if ticker.blank?
      ticker = default_ticker
      last_trade = Trade.public_from_influx(market_symbol, 1).first
      ticker[:last] = last_trade[:price] if last_trade.present?
    end

    {
      at: Time.now.to_i,
      avg_price: ticker[:vwap].to_d,
      high: ticker[:max].to_d,
      last: ticker[:last].to_d,
      low: ticker[:min].to_d,
      open: ticker[:first].to_d,
      price_change_percent: change_ratio(ticker[:first].to_d, ticker[:last].to_d),
      volume: ticker[:volume].to_d,
      amount: ticker[:amount].to_d
    }.transform_values(&:to_s)
  end

  def change_ratio(open, last)
    percent = open.zero? ? 0 : (last - open) / open * 100

    # Prepend sign. Show two digits after the decimal point. Append '%'.
    "#{'%+.2f' % percent}%"
  end
end
