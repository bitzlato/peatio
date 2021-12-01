# frozen_string_literal: true

module CurrencyServices
  class SwapPrice
    PRICE_DEVIATION = 0.002
    DEVIATION_PRECISION = 3
    QUOTE_PRICE_PRECISION = 8

    attr_reader :volume

    def initialize(from_currency:, to_currency:, volume:)
      @from_currency = from_currency
      @to_currency = to_currency
      @volume = volume
    end

    def market
      @market ||= Market.where(base: @from_currency, quote: @to_currency)
                        .or(Market.where(base: @to_currency, quote: @from_currency)).first!
    end

    def market?
      !!market
    rescue ActiveRecord::RecordNotFound
      false
    end

    def side
      @side ||= if market.base == @from_currency
                  'sell'
                elsif market.base == @to_currency
                  'buy'
                else
                  raise "Wrong currencies: #{@from_currency.id} => #{@to_currency.id}"
                end
    end

    def sell?
      side == 'sell'
    end

    def buy?
      side == 'buy'
    end

    def price
      @price ||= begin
        price = if sell?
                  OrderBid.top_price(market.symbol).yield_self { |p| p - (p * PRICE_DEVIATION) }
                else
                  OrderAsk.top_price(market.symbol).yield_self { |p| p + (p * PRICE_DEVIATION) }
                end

        market.round_price(price.to_d)
      end
    end

    def inverse_price
      (1 / price).to_d.round(QUOTE_PRICE_PRECISION)
    end

    def request_price
      if sell?
        price
      else
        inverse_price
      end
    end

    def valid_price?(price)
      ((request_price - price) / price).abs.round(DEVIATION_PRECISION) <= PRICE_DEVIATION
    end

    def conver_amount_to_base(request_amount)
      request_amount /= price if buy?

      market.round_amount(request_amount.to_d)
    end
  end
end
