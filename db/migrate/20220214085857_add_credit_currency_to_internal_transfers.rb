# frozen_string_literal: true

class AddCreditCurrencyToInternalTransfers < ActiveRecord::Migration[5.2]
  def change
    add_column :internal_transfers, :credit_currency_id, :string, length: 20
  end
end
