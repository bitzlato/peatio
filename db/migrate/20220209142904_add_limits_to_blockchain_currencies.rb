# frozen_string_literal: true

class AddLimitsToBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchain_currencies, :withdraw_fee, :decimal, precision: 32, scale: 18, default: 0, null: false
    add_column :blockchain_currencies, :min_deposit_amount, :decimal, precision: 32, scale: 18, default: 0, null: false

    BlockchainCurrency.find_each do |blockchain_currency|
      blockchain_currency.update_column(:withdraw_fee, blockchain_currency.currency.withdraw_fee)
      blockchain_currency.update_column(:min_deposit_amount, blockchain_currency.currency.min_deposit_amount)
    end
  end
end
