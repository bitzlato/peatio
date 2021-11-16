# frozen_string_literal: true

module Workers
  module Daemons
    class PaymentAddressBalancer < Base
      @sleep_time = 10

      def process
        return unless Rails.env.production? || Rails.env.sandbox?

        Rails.logger.info('Update payment addresses balances')
        PaymentAddress.active.where.not(address: nil).find_each do |payment_address|
          BalancesUpdater.new(blockchain: payment_address.blockchain, address: payment_address.address).perform
        end
      end
    end
  end
end
