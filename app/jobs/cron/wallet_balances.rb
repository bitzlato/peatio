# frozen_string_literal: true

module Jobs
  module Cron
    module WalletBalances
      def self.process
        return if Rails.env.staging?  # Стейджи не имеют доступа в шлюзы

        Rails.logger.info('Update wallets balances')
        Wallet.active_retired.find_each do |wallet|
          BalancesUpdater.new(blockchain: wallet.blockchain, address: wallet.address).perform
        end

        sleep 30
      end
    end
  end
end
