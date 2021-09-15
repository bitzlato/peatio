# frozen_string_literal: true

module Jobs
  module Cron
    module WalletBalances
      def self.process
        # Стейджи не имеют доступа в шлюзы
        return if Rails.env.staging?

        Rails.logger.info('Update wallets balances')
        Wallet.find_each(&:update_balances!)
        sleep 30
      end
    end
  end
end
