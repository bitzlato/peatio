# frozen_string_literal: true

module API
  module V2
    module Public
      class Swap < Grape::API
        helpers ::API::V2::Admin::Helpers

        SwapPrice = Struct.new(:price)

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
        end
        get '/swap/price' do
          from_currency = ::Currency.find(params[:from_currency])
          to_currency = ::Currency.find(params[:to_currency])
          swap_price_service = CurrencyServices::SwapPrice.new(from_currency: from_currency, to_currency: to_currency)

          error!({ errors: ['market.swap.no_appropriate_market'] }, 422) unless swap_price_service.market?

          swap_price = swap_price_service.request_price
          error!({ errors: ['market.swap.no_swap_price'] }, 422) unless swap_price

          price = SwapPrice.new(swap_price)

          present price, with: API::V2::Entities::SwapPrice
        end
      end
    end
  end
end
