# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class Withdraw < Base
        expose(
          :id,
          documentation: {
            type: Integer,
            desc: 'The withdrawal id.'
          }
        )

        expose(
          :currency_id,
          as: :currency,
          documentation: {
            type: String,
            desc: 'The currency code.'
          }
        )

        expose(
          :type,
          documentation: {
            type: String,
            desc: 'The withdrawal type'
          }
        ) { |w| w.currency.fiat? ? :fiat : :coin }

        expose(
          :sum,
          as: :amount,
          documentation: {
            type: String,
            desc: 'The withdrawal amount'
          }
        )

        expose(
          :fee,
          documentation: {
            type: BigDecimal,
            desc: 'The exchange fee.'
          }
        )

        expose(
          :txid,
          as: :blockchain_txid,
          documentation: {
            type: String,
            desc: 'The withdrawal transaction id.'
          }
        )

        expose(
          :rid,
          documentation: {
            type: String,
            desc: 'The beneficiary ID or wallet address on the Blockchain.'
          }
        )

        expose(
          :aasm_state,
          as: :state,
          documentation: {
            type: String,
            desc: 'The withdrawal state.'
          }
        )

        expose(
          :confirmations,
          if: ->(withdraw) { withdraw.currency.coin? },
          documentation: {
            type: Integer,
            desc: 'Number of confirmations.'
          }
        )

        expose(
          :note,
          documentation: {
            type: String,
            desc: 'Withdraw note.'
          }
        )

        expose(
          :transfer_type,
          documentation: {
              type: String,
              desc: 'Withdraw transfer type'
          }
        )

        expose(
          :created_at,
          :updated_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'The datetimes for the withdrawal.'
          }
        )

        expose(
          :completed_at,
          as: :done_at,
          format_with: :iso8601,
          documentation: {
            type: String,
            desc: 'The datetime when withdraw was completed'
          }
        )

        expose(
          :transfer_links,
          if: ->(withdraw) { withdraw.metadata.has_key? 'links' },
          documentation: {
            type: JSON,
            desc: 'Links to confirm withdraw on external resource',
            example: -> {
              [
                { title: 'telegram', url: 'https://t.me/BTC_STAGE_BOT?start=b_0f8c3db61f223ea9df072fd37e0b6315' },
                { title: 'web', url: 'https://s-www.lgk.one/p2p/?start=b_0f8c3db61f223ea9df072fd37e0b6315' }
              ]
            }
          }
        ) do |withdraw|
          withdraw.metadata['links']
        end
      end
    end
  end
end
