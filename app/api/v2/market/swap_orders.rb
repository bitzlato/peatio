# frozen_string_literal: true

module API
  module V2
    module Market
      class SwapOrders < Grape::API
        namespace :swap_orders do
          desc 'Get information of specified swap order.',
               success: API::V2::Entities::SwapOrder
          params do
            requires :id,
                     type: String,
                     allow_blank: false,
                     desc: -> { V2::Entities::SwapOrder.documentation[:id] }
          end
          get ':id' do
            user_authorize! :read, ::SwapOrder

            if params[:id].match?(/\A[0-9]+\z/)
              swap_order = current_user.swap_orders.find(params[:id])
            elsif UUID.validate(params[:id])
              swap_order = current_user.swap_orders.find_by!(uuid: params[:id])
            else
              error!({ errors: ['market.swap_order.invaild_id_or_uuid'] }, 422)
            end
            present swap_order, with: API::V2::Entities::SwapOrder, type: :full
          end
        end
      end
    end
  end
end
