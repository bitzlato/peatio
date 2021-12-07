# frozen_string_literal: true

module CurrencyServices
  class DepthPrice
    Error = Class.new(StandardError)
    RequestVolumeCurrencyError = Class.new(Error)
    MarketVolumeError = Class.new(Error)

    def price_for(market:, side:, request_currency:, request_volume:)
      depth = case side.to_s
              when 'sell'
                OrderBid.get_depth(market.symbol)
              when 'buy'
                OrderAsk.get_depth(market.symbol)
              else
                raise 'Wrong side'
              end

      case request_currency
      when market.base
        base_price_for_volume_in_base(depth, request_volume)
      when market.quote
        base_price_for_volume_in_quote(depth, request_volume)
      else
        raise RequestVolumeCurrencyError, "Request currency must be a #{market.base_unit} or #{market.quote_unit}"
      end
    end

    private

    def base_price_for_volume_in_base(depth, volume)
      volume = volume.dup
      total_price = 0
      total_volume = 0
      depth.each do |p, v|
        if volume <= v
          total_price += p * volume
          total_volume += volume
          volume = 0
        else
          total_price += p * v
          total_volume += v
          volume -= v
        end

        break if volume.zero?
      end

      raise MarketVolumeError, 'Not enough volume on market' unless volume.zero?

      total_price / total_volume
    end

    def base_price_for_volume_in_quote(depth, volume)
      volume = volume.dup
      total_price = 0
      total_volume = 0
      depth.each do |p, v|
        converted_volume = (volume / p)
        if converted_volume <= v
          total_price += p * converted_volume
          total_volume += converted_volume
          volume = 0
        else
          total_price += p * v
          total_volume += converted_volume
          volume -= (converted_volume - v) * p
        end

        break if volume.zero?
      end

      raise MarketVolumeError, 'Not enough volume on market' unless volume.zero?

      total_price / total_volume
    end
  end
end
