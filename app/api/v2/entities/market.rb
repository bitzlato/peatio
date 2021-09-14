# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Entities
      class Market < Base
        expose(
          :symbol,
          as: :id,
          documentation: {
            type: String,
            desc: 'Id has been renamed to symbol. This field will be deprecated soon.'
          }
        )

        expose(
          :symbol,
          documentation: {
            type: String,
            desc: "Unique market ticker symbol. It's always in the form of xxxyyy,"\
                  'where xxx is the base currency code, yyy is the quote'\
                  "currency code, e.g. 'btcusd'. All available markets can"\
                  'be found at /api/v2/markets.'
          }
        )

        expose(
          :name,
          documentation: {
            type: String,
            desc: 'Market name.'
          }
        )

        expose(
          :type,
          documentation: {
            type: String,
            desc: 'Market type.'
          }
        )

        expose(
          :base_unit,
          documentation: {
            type: String,
            desc: 'Market Base unit.'
          }
        )

        expose(
          :quote_unit,
          documentation: {
            type: String,
            desc: 'Market Quote unit.'
          }
        )

        expose(
          :min_price,
          documentation: {
            type: BigDecimal,
            desc: 'Minimum order price.'
          }
        )

        expose(
          :max_price,
          documentation: {
            type: BigDecimal,
            desc: 'Maximum order price.'
          }
        )

        expose(
          :min_amount,
          documentation: {
            type: BigDecimal,
            desc: 'Minimum order amount.'
          }
        )

        expose(
          :amount_precision,
          documentation: {
            type: BigDecimal,
            desc: 'Precision for order amount.'
          }
        )

        expose(
          :price_precision,
          documentation: {
            type: BigDecimal,
            desc: 'Precision for order price.'
          }
        )

        expose(
          :state,
          documentation: {
            type: String,
            desc: 'Market state defines if user can see/trade on current market.'
          }
        )
      end
    end
  end
end
