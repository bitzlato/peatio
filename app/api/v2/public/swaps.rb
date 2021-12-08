# frozen_string_literal: true

module API
  module V2
    module Public
      class Swaps < Grape::API
        helpers ::API::V2::Admin::Helpers

        desc 'Get swap price' do
          success API::V2::Entities::SwapPrice
        end
        params do
          requires :from_currency,
                   values: { value: -> { ::Currency.ids }, message: 'arket.currency_doesnt_exist' },
                   desc: -> { API::V2::Management::Entities::Market.documentation[:base_unit][:desc] }
          requires :to_currency,
                   values: { value: -> { ::Currency.ids }, message: 'market.currency_doesnt_exist' },
                   desc: -> { API::V2::Management::Entities::Market.documentation[:quote_unit][:desc] }
          requires :request_currency,
                   values: { value: -> { ::Currency.ids }, message: 'market.currency_doesnt_exist' },
                   desc: -> { API::V2::Management::Entities::Market.documentation[:quote_unit][:desc] }
          requires :request_volume,
                   type: { value: BigDecimal, message: 'market.swap_order.non_decimal_volume' },
                   values: { value: ->(v) { v.try(:positive?) }, message: 'market.swap_order.non_positive_volume' }
        end
        get '/swap/price' do
          from_currency = ::Currency.find(params[:from_currency])
          to_currency = ::Currency.find(params[:to_currency])
          request_currency = ::Currency.find(params[:request_currency])

          swap_price_service = CurrencyServices::SwapPrice.new(from_currency: from_currency, to_currency: to_currency,
                                                               request_currency: request_currency, request_volume: params[:request_volume])

          error!({ errors: ['market.swap.invalid_market'] }, 422) unless swap_price_service.market?

          present swap_price_service.price_object, with: API::V2::Entities::SwapPrice
        rescue CurrencyServices::SwapPrice::ExchangeCurrencyError, CurrencyServices::DepthPrice::RequestVolumeCurrencyError => _e
          error!({ errors: ['market.swap_order.invalid_currency'] }, 422)
        rescue CurrencyServices::DepthPrice::MarketVolumeError => _e
          error!({ errors: ['market.swap_order.invalid_market_volume'] }, 422)
        end

        get '/swap/limits' do
          swap_config = Rails.application.config_for(:swap)

          present swap_config, with: API::V2::Entities::SwapLimits
        end
      end
    end
  end
end
