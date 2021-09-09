module Jobs
  module Cron
    module WalletBalances
      def self.process
        # Стейджи не имеют доступа в шлюзы
        return if Rails.env.staging?
        Wallet.find_each do |wallet|
          wallet.update_balances!
        end
        sleep 30
      end

    end
  end
end
