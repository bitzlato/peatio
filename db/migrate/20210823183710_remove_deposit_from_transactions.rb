# frozen_string_literal: true

class RemoveDepositFromTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :is_followed, :boolean, null: false, default: false
  end
end
