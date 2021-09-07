module Jobs
  module Cron
    class CurrencyPricer
      def self.process
        Currency.each do |currency|
          currency.update! price: get_price_in_usd_for(currency)
        end
      end

      def self.get_price_in_usd_for(currency)
      rescue
        1
      end
    end
  end
end
