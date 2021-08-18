module Jobs
  module Cron
    class PaymentAddressBalancer
      def self.process
        PaymentAddress.where.not(address: nil).find_each(&method(:update_balance))
        sleep 10
      end

      def self.update_balance(payment_address)
        if payment_address.blockchain.gateway.enable_personal_address_balance?
          update_balance_by_currency payment_address
        else
          update_balances(payment_address)
        end
      end

      def self.update_balances payment_address
        payment_address.update!(
          balances: payment_address.blockchain.gateway.load_balances(payment_address.address).select { |c,v| v.positive? }.transform_keys { |k| k.id },
          balances_updated_at: Time.zone.now
        )
      rescue StandardError => err
        Rails.logger.warn "#{err} for payment_address id #{payment_address.id}"
        report_exception err, true, payment_address_id: payment_address.id
      end

      def self.update_balance_by_currency payment_address
        balances = payment_address.currencies.each_with_object({}).each do |currency, hash|
          hash[currency.id.downcase] =
            payment_address.
            blockchain.
            gateway.
            load_balance(payment_address.address, currency)
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
