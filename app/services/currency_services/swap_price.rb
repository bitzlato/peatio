# frozen_string_literal: true

module CurrencyServices
  class SwapPrice
    PRICE_DEVIATION = '0.02'.to_d
    PRICE_DEVIATION_PRECISION = 2

    PriceObject = Struct.new(:from_currency, :to_currency, :request_currency,
                             :request_volume, :request_price, :inverse_price,
                             :from_volume, :to_volume)

    def initialize(from_currency:, to_currency:, volume_currency:, volume:)
      @from_currency = from_currency
      @to_currency = to_currency
      @volume_currency = volume_currency
      @volume = volume.to_d
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
        deviation = market_price * PRICE_DEVIATION
        price = sell? ? market_price - deviation : market_price + deviation
        market.round_price(price.to_d)
      end
    end

    def inverse_price
      (1 / price).to_d.round(8)
    end

    def valid_price?(price)
      ((price_object.request_price - price) / price).abs.round(PRICE_DEVIATION_PRECISION) <= PRICE_DEVIATION
    end

    def price_object
      @price_object ||= PriceObject.new.tap do |price_obj|
        price_obj[:from_currency]     = @from_currency
        price_obj[:to_currency]       = @to_currency
        price_obj[:request_currency]  = @volume_currency
        price_obj[:request_volume]    = @volume

        if @volume_currency == market.base
          price_obj[:request_price] = price
          price_obj[:inverse_price] = inverse_price
          if @volume_currency == @from_currency
            price_obj[:from_volume] = @volume
            price_obj[:to_volume] = market.round_amount(price * @volume)
          elsif @volume_currency == @to_currency
            price_obj[:from_volume] = market.round_amount(inverse_price * @volume)
            price_obj[:to_volume] = @volume
          end
        elsif @volume_currency == market.quote
          price_obj[:request_price] = inverse_price
          price_obj[:inverse_price] = price
          if @volume_currency == @from_currency
            price_obj[:from_volume] = @volume
            price_obj[:to_volume] = market.round_amount(inverse_price * @volume)
          elsif @volume_currency == @to_currency
            price_obj[:from_volume] = market.round_amount(price * @volume)
            price_obj[:to_volume] = @volume
          end
        end
      end
    end


    # Return prices and amounts
    # automaticaly convert amount in quote to base
    # [[price, amount]]
    # [[0.7403e1, 0.989e0], [0.7403609e1, 0.98891864764]]
    def raw_market_prices_with_amounts
      return @raw_market_prices_with_amounts if @raw_market_prices_with_amounts

      market_depth = sell? ? OrderBid.get_depth(market.symbol) : OrderAsk.get_depth(market.symbol)
      volume = @volume.dup

      @raw_market_prices_with_amounts = if market.base == @volume_currency
        market_depth.each_with_object([]) do |(p, v), arr|
          if volume <= v
            arr << [p, volume]
            volume = 0
          else
            arr << [p, v]
            volume -= v
          end
          break arr if volume.zero?
        end
      elsif market.quote == @volume_currency
        market_depth.each_with_object([]) do |(p, v), arr|
          converted_volume = (1 / p) * volume
          if converted_volume <= v
            arr << [p, converted_volume]
            volume = 0
          else
            arr << [p, v]
            volume -= (converted_volume - v) * p
          end
          break arr if volume.zero?
        end
      else
        raise "Volume currency must be a #{market.base_unit} or #{market.quote_unit}"
      end
    end

    def market_amount
      @market_amount ||= raw_market_prices_with_amounts.sum { |_price, volume| volume }
    end

    def market_price
      @market_price ||= raw_market_prices_with_amounts.yield_self do |arr|
                          arr.sum { |price, volume| price * volume } / market_amount
                        end
    end
  end
end
