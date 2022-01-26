# frozen_string_literal: true

class RemoveColumnsFromCurrencies < ActiveRecord::Migration[5.2]
  def change
    remove_column :currencies, :parent_id, :string
    remove_column :currencies, :blockchain_id, :bigint
    remove_column :currencies, :base_factor, :bigint
    remove_column :currencies, :contract_address, :string
  end
end
