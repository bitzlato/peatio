# frozen_string_literal: true

class AddAccountablFeeIndexToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_index :transactions, :fee_currency_id
  end
end
