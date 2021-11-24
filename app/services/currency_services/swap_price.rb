# frozen_string_literal: true

module CurrencyServices
  class SwapPrice
    PRICE_DEVIATION = 0.002
    QUOTE_PRICE_PRECISION = 8

    def initialize(from_currency:, to_currency:)
      @from_currency = from_currency
      @to_currency = to_currency
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
      @side ||= market.base == @from_currency ? 'sell' : 'buy'
    end

    def sell?
      side == 'sell'
    end

    def buy?
      side == 'buy'
    end

    def price_in_base
      @price_in_base ||= begin
        price = if sell?
                  OrderBid.top_price(market.symbol).yield_self { |p| p - (p * PRICE_DEVIATION) }
                else
                  OrderAsk.top_price(market.symbol).yield_self { |p| p + (p * PRICE_DEVIATION) }
                end

        market.round_price(price.to_d)
      end
    end

    def price_in_quote
      (1 / price_in_base).to_d.round(QUOTE_PRICE_PRECISION)
    end

    def request_price
      if sell?
        price_in_base
      else
        price_in_quote
      end
    end

    def inverse_price
      if sell?
        price_in_quote
      else
        price_in_base
      end
    end

    def valid_price?(price)
      ((request_price - price) / price).abs <= PRICE_DEVIATION
    end

    def conver_amount_to_base(request_amount)
      request_amount /= price_in_base if buy?

      market.round_amount(request_amount.to_d)
    end
  end
end
