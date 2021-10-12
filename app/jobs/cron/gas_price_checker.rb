# frozen_string_literal: true

module Jobs
  module Cron
    class GasPriceChecker
      JOB_TIMEOUT = 30.seconds

      def self.process(job_timeout = JOB_TIMEOUT)
        return if Rails.env.staging?  # Стейджи не имеют доступа в шлюзы

        Blockchain.active.find_each do |blockchain|
          max_gas_price = Rails.configuration.blockchains.dig(blockchain.key, 'max_gas_price')
          next if !blockchain.gateway.is_a?(EthereumGateway) || max_gas_price.nil? || (blockchain.high_transaction_price_at.present? && blockchain.high_transaction_price_at > 5.minutes.ago)

          min_threshold = max_gas_price * 0.98
          max_threshold = max_gas_price * 1.02
          gas_price = EthereumGateway::AbstractCommand.new(blockchain.gateway.client).fetch_gas_price
          if gas_price < min_threshold && !blockchain.high_transaction_price_at.nil?
            blockchain.update!(high_transaction_price_at: nil)
            Peatio::SlackNotifier.instance.ping "Включил выводы для #{blockchain.name}. Цена газа #{gas_price * 1e-9} Gwei ниже, чем #{min_threshold * 1e-9} Gwei."
          elsif gas_price > max_threshold && blockchain.high_transaction_price_at.nil?
            blockchain.update!(high_transaction_price_at: Time.current)
            Peatio::SlackNotifier.instance.ping "Отключил выводы для #{blockchain.name}. Цена газа #{gas_price * 1e-9} Gwei выше, чем #{max_threshold * 1e-9} Gwei."
          end
        end

        sleep job_timeout
      end
    end
  end
end
