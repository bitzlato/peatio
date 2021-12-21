# frozen_string_literal: true

class AddOptionsToBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchain_currencies, :options, :jsonb
  end
end
