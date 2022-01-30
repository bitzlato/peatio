# frozen_string_literal: true

module API
  module V2
    module Entities
      class PaymentAddress < Base
        expose(
          :currencies,
          documentation: {
            desc: 'Currencies codes.',
            is_array: true,
            example: -> { ::Currency.visible.codes }
          }
        ) do |pa|
          pa.blockchain.currencies.codes
        end

        expose(
          :address,
          documentation: {
            desc: 'Payment address.',
            type: String
          }
        )

        expose(
          :state,
          documentation: {
            desc: 'Payment address state.',
            type: String
          }, &:status
        )
      end
    end
  end
end
