module Jobs
  module Cron
    class PaymentAddressBalancer
      def self.process
        PaymentAddress.find_each(&method(:update_balance))
        sleep 10
      end

      def self.update_balance payment_address
        balances = payment_address.currencies.each_with_object({}).each do |currency, hash|
          hash[currency.id] =
            payment_address.
            wallet.
            blockchain.
            blockchain_api.
            load_balance!(payment_address.address, currency.id)
        end
        payment_address.update!(
          balances: balances,
          balances_updated_at: Time.zone.now
        )
      rescue StandardError => err
        Rails.logger.warn "#{err} for payment_address id #{payment_address.id}"
        report_exception err, true, payment_address_id: payment_address.id
      end
    end
  end
end
