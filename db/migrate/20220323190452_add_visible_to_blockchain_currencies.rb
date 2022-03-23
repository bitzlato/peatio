# frozen_string_literal: true

class AddVisibleToBlockchainCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchain_currencies, :visible, :boolean, default: true, null: false
  end
end
