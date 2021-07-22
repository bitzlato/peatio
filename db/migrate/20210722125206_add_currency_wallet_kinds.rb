class AddCurrencyWalletKinds < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies_wallets, :enable_deposit, :boolean, null: false, default: true
    add_column :currencies_wallets, :enable_withdraw, :boolean, null: false, default: true
  end
end
