# frozen_string_literal: true

class ChangeCurrencyIdLimitInBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def change
    change_column :blockchain_currencies, :currency_id, :string, limit: 20
  end
end
