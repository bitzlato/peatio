# frozen_string_literal: true

module CurrencyServices
  class Price
    def initialize(base_currency:, quote_currency:, vwap_time: nil)
      @base_currency = base_currency
      @quote_currency = quote_currency
      @vwap_time = vwap_time || Rails.configuration.currencies['currency_pricer']['vwap_time']
    end

    def call(vwap_time: nil)
      vwap_time = vwap_time || @vwap_time

      price = market_price(base_currency_code: @base_currency.code, quote_currency_code: @quote_currency.code, vwap_time: vwap_time)
      if price.nil?
        intermediate_currency_codes = @quote_currency.dependent_markets.spot.pluck(:base_unit, :quote_unit).flatten.uniq - [@quote_currency.code]
        secondary_market = Market.where(base_unit: @base_currency.code, quote_unit: intermediate_currency_codes).or(
          Market.where(base_unit: intermediate_currency_codes, quote_unit: @base_currency.code)
        ).spot.take
        if secondary_market.nil?
          Rails.logger.warn(message: "Can't calculate currency price. No appropriate markets", currency_code: @base_currency.code)
          return nil
        end
        intermediate_currency_code = ([secondary_market.base_unit, secondary_market.quote_unit] - [@base_currency.code])[0]
        primary_price = market_price(base_currency_code: intermediate_currency_code, quote_currency_code: @quote_currency.code, vwap_time: vwap_time)
        secondary_price = market_price(base_currency_code: @base_currency.code, quote_currency_code: intermediate_currency_code, vwap_time: vwap_time)
        return nil if primary_price.nil? || secondary_price.nil?

        price = primary_price * secondary_price
      end
      price
    end

    private

    def market_price(base_currency_code:, quote_currency_code:, vwap_time:)
      is_forward_market = true
      market = Market.spot.find_by(base_unit: base_currency_code, quote_unit: quote_currency_code)
      if market.nil?
        is_forward_market = false
        market = Market.spot.find_by(base_unit: quote_currency_code, quote_unit: base_currency_code)
      end
      return nil if market.nil?

      price = market.vwap(vwap_time)
      return nil if price.nil?

      is_forward_market ? price : 1.0 / price
    end
  end
end
