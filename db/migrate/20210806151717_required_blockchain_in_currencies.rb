# frozen_string_literal: true

class RequiredBlockchainInCurrencies < ActiveRecord::Migration[5.2]
  def change
    change_column_null :currencies, :blockchain_id, false
  end
end
