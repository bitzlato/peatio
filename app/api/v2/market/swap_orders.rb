# frozen_string_literal: true

module API
  module V2
    module Market
      class SwapOrders < Grape::API
        helpers ::API::V2::Market::NamedParams

        namespace :swap_orders do
          desc 'Get information of specified swap order.',
               success: API::V2::Entities::SwapOrder
          params do
            requires :id,
                     type: Integer,
                     allow_blank: false,
                     desc: -> { V2::Entities::SwapOrder.documentation[:id] }
          end
          get ':id' do
            user_authorize! :read, ::SwapOrder
            swap_order = current_user.swap_orders.find(params[:id])

            present swap_order, with: API::V2::Entities::SwapOrder, type: :full
          end

          desc 'Create a Sell/Buy order.',
               success: API::V2::Entities::SwapOrder
          params do
            use :swap_order
          end
          post do
            user_authorize! :create, ::SwapOrder

            swap_order = create_swap_order(params)
            present swap_order, with: API::V2::Entities::SwapOrder
          end
        end
      end
    end
  end
end
