# frozen_string_literal: true

class AddAmountToTransfers < ActiveRecord::Migration[5.2]
  def change
    add_column :transfers, :amount, :decimal
    Transfer.find_each do |t|
      t.update! amount: t.operations.pluck(:amount).compact.first
    end
    change_column_null :transfers, :amount, false
  end
end
