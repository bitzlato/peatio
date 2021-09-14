# frozen_string_literal: true

class RemoveEnablesFromCurrensiesWallets < ActiveRecord::Migration[5.2]
  def change
    remove_column :currencies_wallets, :enable_deposit
    remove_column :currencies_wallets, :enable_withdraw
  end
end
