# frozen_string_literal: true

module API
  module V2
    module Entities
      class SwapPrice < Base
        expose(
          :from_currency,
          documentation: {
            type: String,
            desc: 'From currency id.'
          }
        )

        expose(
          :from_volume,
          documentation: {
            type: BigDecimal,
            desc: 'From volume.'
          }
        )

        expose(
          :to_currency,
          documentation: {
            type: String,
            desc: 'To currency id.'
          }
        )

        expose(
          :to_volume,
          documentation: {
            type: BigDecimal,
            desc: 'To volume.'
          }
        )

        expose(
          :request_currency,
          documentation: {
            type: String,
            desc: 'Request currency id.'
          }
        )

        expose(
          :request_volume,
          documentation: {
            type: BigDecimal,
            desc: 'Request volume.'
          }
        )

        expose(
          :request_price,
          documentation: {
            type: BigDecimal,
            desc: 'Request price.'
          }
        )

        expose(
          :inverse_price,
          documentation: {
            type: BigDecimal,
            desc: 'Request price.'
          }
        )

        private

        def from_currency
          object.from_currency.id
        end

        def to_currency
          object.to_currency.id
        end

        def request_currency
          object.request_currency.id
        end
      end
    end
  end
end
