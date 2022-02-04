# frozen_string_literal: true

class AddBaseFactorToBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchain_currencies, :base_factor, :bigint
    BlockchainCurrency.find_each do |blockchain_currency|
      blockchain_currency.update_column(:base_factor, blockchain_currency.currency.base_factor)
    end
    change_column_null :blockchain_currencies, :base_factor, false
  end
end
