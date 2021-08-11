# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class Account < Base
        expose(
          :currency_id,
          as: :currency,
          documentation: {
            desc: 'Currency code.',
            type: String
          }
        )

        expose(
          :balance,
          format_with: :decimal,
          documentation: {
            desc: 'Account balance.',
            type: BigDecimal
          }
        )

        expose(
          :locked,
          format_with: :decimal,
          documentation: {
            desc: 'Account locked funds.',
            type: BigDecimal
          }
        )

        expose(
          :deposit_address,
          if: ->(account, _options) do
            account.currency.coin? && account.payment_address.address.present? && !account.enable_invoice?
          end,
          using: API::V2::Entities::PaymentAddress,
          documentation: {
            desc: 'User deposit address',
            type: String
          }
        ) do |account, options|
          account.payment_address
        end

        expose(
          :enable_invoice,
          if: ->(account, _options) { account.enable_invoice? },
          documentation: {
            desc: 'Show intention form instead of payment address generation',
            type: JSON
          }
        )
      end
    end
  end
end
