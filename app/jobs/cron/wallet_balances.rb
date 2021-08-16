module Jobs
  module Cron
    module WalletBalances
      def self.process
        Wallet.active.find_each do |w|
          w.update!(balance: w.current_balance)
        rescue StandardError => e
          report_exception(e, true, wallet_id: w.id)
          next
        end
        sleep 30
      end
    end
  end
end
