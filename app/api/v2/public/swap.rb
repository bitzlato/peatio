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
          market = ::Market.find_by_currencies(params[:from_currency], params[:to_currency])
          error!({ errors: ['market.swap.no_appropriate_market'] }, 422) unless market

          swap_price = market.price_in(market.swap_price, params[:from_currency])
          error!({ errors: ['market.swap.no_swap_price'] }, 422) unless swap_price

          price = SwapPrice.new(swap_price)

          present price, with: API::V2::Entities::SwapPrice
        end
      end
    end
  end
end
