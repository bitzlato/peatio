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
          if: lambda do |account, _options|
            account.currency.coin? && !account.enable_invoice? && account.payment_address.try(:address).present?
          end,
          using: API::V2::Entities::PaymentAddress,
          documentation: {
            desc: 'User deposit address',
            type: String
          }
        ) do |account, options|
          account.payment_address
        rescue StandardError => e
          report_exception e, true, account: account, options: options
          nil
        end

        expose(
          :enable_invoice,
          if: ->(account, _options) { account.enable_invoice? },
          documentation: {
            desc: 'Show intention form instead of payment address generation',
            type: 'boolean'
          }
        )
      end
    end
  end
end
