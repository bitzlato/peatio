# frozen_string_literal: true

namespace :data_migrations do
  desc 'Fill blockchain_currencies.base_factor'
  task fill_base_factor: :environment do
    BlockchainCurrency.where(base_factor: nil).find_each do |blockchain_currency|
      blockchain_currency.update_column(:base_factor, blockchain_currency.currency.base_factor)
    end
  end
end
