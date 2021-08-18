module Jobs
  module Cron
    class PaymentAddressBalancer
      def self.process
        PaymentAddress.where.not(address: nil).find_each(&method(:update_balance))
        sleep 10
      end

      def self.update_balances payment_address
        return unless payment_address.blockchain.gateway.enable_personal_address_balance?
        payment_address.update!(
          balances: convert_balances(payment_address.blockchain.load_balances(payment_address.address)),
          balances_updated_at: Time.zone.now
        )
      rescue StandardError => err
        Rails.logger.warn "#{err} for payment_address id #{payment_address.id}"
        report_exception err, true, payment_address_id: payment_address.id
      end

      def self.convert_balances(balances)
        balances.each_with_object({}) do |(k,v), a|
          currency_id = k.is_a?(Money::Currency) ? k.id.downcase : k
          a[currency_id] = v.to_d
        end
      end
    end
  end
end
