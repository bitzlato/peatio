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
          if: ->(account, _options) { account.currency.coin? && !Wallet.deposit_wallet(account.currency_id)&.settings&.fetch('enable_intention', false) },
          using: API::V2::Entities::PaymentAddress,
          documentation: {
            desc: 'User deposit address',
            type: String
          }
        ) do |account, options|
          wallet = Wallet.deposit_wallet(account.currency_id)
          ::PaymentAddress.find_by(wallet: wallet, member: options[:current_user], remote: false)
        end

        expose(
          :enable_intention,
          if: ->(account, _options) { Wallet.deposit_wallet(account.currency_id)&.settings&.fetch('enable_intention', false) },
          documentation: {
            desc: 'Show intention form instead of payment address generation',
            type: JSON
          }
        ) do |account, options|
          true
        end
      end
    end
  end
end
