# frozen_string_literal: true

module API
  module V2
    module Entities
      class Currency < Base
        expose(
          :id,
          documentation: {
            desc: 'Currency code.',
            type: String,
            values: -> { ::Currency.visible.codes },
            example: -> { ::Currency.visible.first.id }
          }
        )

        expose(
          :cc_code,
          documentation: {
            desc: 'Currency code in Bitzlato P2P',
            type: String,
            values: -> { ::Currency.pluck(:cc_code).uniq },
            example: -> { ::Currency.pluck(:cc_code).first || 'BTC' }
          }
        )

        expose(
          :name,
          documentation: {
            type: String,
            desc: 'Currency name',
            example: -> { ::Currency.visible.first.name }
          },
          if: ->(currency) { currency.name.present? }
        )

        expose(
          :description,
          documentation: {
            type: String,
            desc: 'Currency description',
            example: -> { ::Currency.visible.first.id }
          }
        )

        expose(
          :icon_id,
          documentation: {
            type: String,
            desc: 'Icon identifier',
            example: -> { ::Currency.visible.first.try(:icon_key) || 'usdt' }
          }
        )

        expose(
          :homepage,
          documentation: {
            type: String,
            desc: 'Currency homepage',
            example: -> { ::Currency.visible.first.homepage }
          }
        )

        expose(
          :price,
          documentation: {
            desc: 'Currency current price'
          }
        )

        expose(
          :type,
          documentation: {
            type: String,
            values: -> { ::Currency.types },
            desc: 'Currency type',
            example: -> { ::Currency.visible.first.type }
          }
        )

        expose(
          :deposit_enabled,
          documentation: {
            type: String,
            desc: 'Currency deposit possibility status (true/false).'
          }
        )

        expose(
          :withdrawal_enabled,
          documentation: {
            type: String,
            desc: 'Currency withdrawal possibility status (true/false).'
          }
        )

        expose(
          :deposit_fee,
          documentation: {
            desc: 'Currency deposit fee',
            example: -> { ::Currency.visible.first.deposit_fee }
          }
        )

        expose(
          :min_withdraw_amount,
          documentation: {
            desc: 'Minimal withdraw amount',
            example: -> { ::Currency.visible.first.min_withdraw_amount }
          }
        )

        expose(
          :withdraw_limit_24h,
          documentation: {
            desc: 'Currency 24h withdraw limit (deprecated)',
            example: -> { ::Currency.visible.first.withdraw_limit_24h }
          }
        )

        expose(
          :withdraw_limit_72h,
          documentation: {
            desc: 'Currency 72h withdraw limit (deprecated)',
            example: -> { ::Currency.visible.first.withdraw_limit_72h }
          }
        )

        expose(
          :precision,
          documentation: {
            desc: 'Currency precision',
            example: -> { ::Currency.visible.first.precision }
          }
        )

        expose(
          :position,
          documentation: {
            desc: 'Position used for defining currencies order',
            example: -> { ::Currency.visible.first.precision }
          }
        )

        expose(
          :icon_url,
          documentation: {
            desc: 'Currency icon',
            example: 'https://upload.wikimedia.org/wikipedia/commons/0/05/Ethereum_logo_2014.svg'
          },
          if: ->(currency) { currency.icon_url.present? }
        )

        expose(
          :blockchain_currencies,
          documentation: {
            is_array: true,
            desc: 'Blockchain currencies'
          }
        ) do |currency, _options|
          # TODO: rollback after deploying and testing tron mainnnet blockchain
          currency.blockchain_currencies
                  .joins(:blockchain)
                  .where.not(blockchains: { key: 'tron-mainnet'})
              .as_json(only: %i[blockchain_id withdraw_fee min_deposit_amount])
        end
      end
    end
  end
end
