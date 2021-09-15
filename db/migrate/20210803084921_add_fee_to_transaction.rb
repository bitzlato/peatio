# frozen_string_literal: true

class AddFeeToTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :fee, :decimal, precision: 32, scale: 16
    add_column :transactions, :fee_currency_id, :string
  end
end
