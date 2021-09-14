# frozen_string_literal: true

class AddBalanceUpdatedAtToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :balance_updated_at, :timestamp
  end
end
