module Jobs
  module Cron
    module WalletBalances
      def self.process
        Wallet.active.find_each do |w|
          Sentry.with_scope do |scope|
            scope.set_tags(wallet_id: w.id)
            w.update!(balance: w.current_balance)
          rescue StandardError => e
            report_exception(e)
            next
          end
        end
        sleep 60
      end
    end
  end
end
