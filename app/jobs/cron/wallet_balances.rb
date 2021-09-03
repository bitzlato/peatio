module Jobs
  module Cron
    module WalletBalances
      def self.process
        Wallet.active.find_each do |w|
          # TODO Получать балансы со шлюза
          balances = w.current_balance.each_with_object({}) do |(k,v), a|
            currency_id = k.is_a?(Money::Currency) ? k.id.downcase : k
            a[currency_id] = v.nil? ? nil : v.to_d
          end

          w.update!(balance: balances, balance_updated_at: Time.zone.now)
        rescue StandardError => e
          report_exception(e, true, wallet_id: w.id)
          next
        end
        sleep 30
      end
    end
  end
end
