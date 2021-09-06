module Jobs
  module Cron
    module WalletBalances
      def self.process
        # Стейджи не имеют доступа в шлюзы
        return if Rails.env.staging?
        Wallet.active.find_each do |wallet|
          update_balances wallet
        end
        sleep 30
      end

      def self.update_balances(wallet)
        # TODO Получать балансы со шлюза
        balances = wallet.current_balance.each_with_object({}) do |(k,v), a|
          currency_id = k.is_a?(Money::Currency) ? k.id.downcase : k
          a[currency_id] = v.nil? ? nil : v.to_d
        end

        wallet.update!(balance: balances, balance_updated_at: Time.zone.now)
      rescue StandardError => e
        report_exception(e, true, wallet_id: wallet.id)
      end
    end
  end
end
