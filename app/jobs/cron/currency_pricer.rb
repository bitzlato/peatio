# frozen_string_literal: true

module Jobs
  module Cron
    class CurrencyPricer
      JOB_TIMEOUT = 5.minutes

      def self.process
        quote_currency = Currency.find(Rails.configuration.currencies['currency_pricer']['quote_currency_code'])
        Currency.find_each do |currency|
          price = CurrencyServices::Price.new(base_currency: currency, quote_currency: quote_currency).call
          next if price.nil?

          currency.update!(price: price)
        end

        sleep JOB_TIMEOUT
      end
    end
  end
end
