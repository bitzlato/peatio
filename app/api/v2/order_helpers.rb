# frozen_string_literal: true

module API
  module V2
    module OrderHelpers
      DESCRIBED_ERRORS_MESSAGES = %w[
        market.account.insufficient_balance
        market.order.insufficient_market_liquidity
        market.order.invalid_volume_or_price
        market.order.open_orders_limit
      ].freeze

      ORDER_CREATE_SERVICES = {
        order: ::OrderServices::CreateOrder,
        swap_order: ::OrderServices::CreateSwapOrder
      }.freeze

      def create_order(attrs, order_create_service: :order)
        market = ::Market.active.find_spot_by_symbol(attrs[:market])
        service = ORDER_CREATE_SERVICES[order_create_service].new(member: current_user)
        service_params = attrs.merge(market: market).symbolize_keys

        result = service.perform(**service_params)

        if result.successful?
          result.data
        else
          error_message = result.errors.first

          if DESCRIBED_ERRORS_MESSAGES.include?(error_message.to_s)
            report_api_error(error_message, request)
          else
            report_exception(error_message)
          end

          error!({ errors: [error_message] }, 422)
        end
      end

      def order_param
        params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
      end
    end
  end
end
