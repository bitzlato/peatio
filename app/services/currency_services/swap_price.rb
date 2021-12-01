# frozen_string_literal: true

module CurrencyServices
  class SwapPrice
    PRICE_DEVIATION = '0.02'.to_d
    PRICE_DEVIATION_PRECISION = 2

    def initialize(from_currency:, to_currency:, request_volume:)
      @from_currency = from_currency
      @to_currency = to_currency
      @request_volume = request_volume.to_d
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
      market.round_price(1 / price)
    end

    def request_price
      if sell?
        price
      else
        inverse_price
      end
    end

    def request_volume
      market.round_amount(@request_volume)
    end

    def volume
      if sell?
        request_volume
      else
        market.round_amount(request_volume / price)
      end
    end

    def valid_price?(price)
      ((request_price - price) / price).abs.round(PRICE_DEVIATION_PRECISION) <= PRICE_DEVIATION
    end
  end
end
