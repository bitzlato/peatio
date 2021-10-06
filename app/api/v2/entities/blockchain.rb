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
      end
    end
  end
end
