# frozen_string_literal: true

class ChangeBlockchainIdNullInCurrencies < ActiveRecord::Migration[5.2]
  def change
    change_column_null :currencies, :blockchain_id, true
  end
end
