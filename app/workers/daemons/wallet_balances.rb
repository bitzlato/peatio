# frozen_string_literal: true

module Workers
  module Daemons
    class WalletBalances < Base
      @sleep_time = 30

      def process
        return if Rails.env.staging?  # Стейджи не имеют доступа в шлюзы

        Rails.logger.info('Update wallets balances')
        Wallet.active_retired.find_each do |wallet|
          BalancesUpdater.new(blockchain: wallet.blockchain, address: wallet.address).perform
        end
      end
    end
  end
end
