# frozen_string_literal: true

module Workers
  module Daemons
    class BargainerJob < Base
      TIMEOUT_RANGE = (3.0..10.0).freeze

      def process(timeout_range = TIMEOUT_RANGE)
        Rails.logger.info { 'Start bargainer process' }

        bargainer = Bargainer.new
        member = Member.find_by!(uid: ENV.fetch('BARGAINER_UID'))
        Rails.configuration.bargainers.each do |bargainer_config|
          market = Market.find_by(symbol: bargainer_config.fetch('market_symbol'))
          if market.nil?
            Rails.logger.warn { { message: 'Makret is not found', market_symbol: bargainer_config.fetch('market_symbol'), service: 'bargainer' } }
            next
          elsif market.state != 'enabled'
            Rails.logger.warn do
              { message: 'Makret is not enabled. Bargain is skipped', market_symbol: market.symbol, market_state: market.state, service: 'bargainer' }
            end
            next
          end

          bargainer.call(
            market: market,
            member: member,
            volume_range: bargainer_config.fetch('min_volume')..bargainer_config.fetch('max_volume'),
            price_deviation: bargainer_config.fetch('price_deviation'),
            max_spread: bargainer_config.fetch('max_spread')
          )
        end

        sleep rand timeout_range
      end
    end
  end
end
