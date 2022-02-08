# frozen_string_literal: true

module API
  module V2
    module Entities
      class Blockchain < API::V2::Entities::Base
        expose(
          :id,
          documentation: {
            type: Integer,
            desc: 'Unique blockchain identifier in database.'
          }
        )

        expose(
          :key,
          documentation: {
            type: String,
            desc: 'Unique key to identify blockchain.'
          }
        )

        expose(
          :name,
          documentation: {
            type: String,
            desc: 'A name to identify blockchain.'
          }
        )

        expose(
          :height,
          documentation: {
            type: Integer,
            desc: 'The number of blocks preceding a particular block on blockchain.'
          }
        )

        expose(
          :explorer_address,
          documentation: {
            type: String,
            desc: 'Blockchain explorer address template.'
          }
        )

        expose(
          :explorer_transaction,
          documentation: {
            type: String,
            desc: 'Blockchain explorer transaction template.'
          }
        )

        expose(
          :min_confirmations,
          documentation: {
            type: Integer,
            desc: 'Minimum number of confirmations.'
          }
        )

        expose(
          :status,
          documentation: {
            type: String,
            desc: 'Blockchain status (active/disabled).'
          }
        )

        expose(
          :is_transaction_price_too_high,
          documentation: {
            type: String,
            desc: 'Transaction price is too high (true/false).'
          }
        ) do |blockchain, _options|
          blockchain.high_transaction_price_at.present?
        end
      end
    end
  end
end
