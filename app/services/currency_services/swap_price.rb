# frozen_string_literal: true

module CurrencyServices
  class SwapPrice
    PRICE_DEVIATION = '0.005'.to_d
    PRICE_DEVIATION_PRECISION = 2

    PriceObject = Struct.new(:from_currency, :to_currency, :request_currency,
                             :request_volume, :request_price, :inverse_price,
                             :from_volume, :to_volume)

    Error = Class.new(StandardError)
    ExchangeCurrencyError = Class.new(Error)

    def initialize(from_currency:, to_currency:, request_currency:, request_volume:)
      @from_currency = from_currency
      @to_currency = to_currency
      @request_currency = request_currency
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
                  raise ExchangeCurrencyError, "Wrong currencies: #{@from_currency.id} => #{@to_currency.id}"
                end
    end

    def sell?
      side == 'sell'
    end

    def buy?
      side == 'buy'
    end

    def market_depth_price
      @market_depth_price ||= CurrencyServices::DepthPrice.new.price_for(
        market: market,
        side: side,
        request_currency: @request_currency,
        request_volume: @request_volume
      )
    end

    def price
      @price ||= begin
        deviation = market_depth_price * PRICE_DEVIATION
        price = sell? ? market_depth_price - deviation : market_depth_price + deviation
        market.round_price(price.to_d)
      end
    end

    def volume
      v = if @from_currency == market.base
            price_object.from_volume
          else
            price_object.to_volume
          end
      market.round_amount(v)
    end

    def inverse_price
      (1 / price).to_d.round(8)
    end

    def valid_price?(price)
      return false unless price_object.request_price

      ((price_object.request_price - price) / price).abs.round(PRICE_DEVIATION_PRECISION) <= PRICE_DEVIATION
    end

    def price_object
      @price_object ||= PriceObject.new.tap do |price_obj|
        price_obj[:from_currency]     = @from_currency.id
        price_obj[:to_currency]       = @to_currency.id
        price_obj[:request_currency]  = @request_currency.id
        price_obj[:request_volume]    = @request_volume

        if sell?
          price_obj[:request_price] = price
          price_obj[:inverse_price] = inverse_price
        else
          price_obj[:request_price] = inverse_price
          price_obj[:inverse_price] = price
        end

        if @request_currency == @from_currency
          price_obj[:from_volume] = @request_volume
          price_obj[:to_volume] = market.round_amount(price_obj.request_price * @request_volume)
        elsif @request_currency == @to_currency
          price_obj[:from_volume] = market.round_amount(price_obj.inverse_price * @request_volume)
          price_obj[:to_volume] = @request_volume
        end
      end
    end
  end
end
