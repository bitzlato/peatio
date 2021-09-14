# frozen_string_literal: true

class AddExpiresAtFieldToDeposit < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :invoice_expires_at, :datetime, default: nil, null: true

    Deposit.invoiced.find_each do |d|
      d.update_column :invoice_expires_at, d.created_at + 1.day
    end
  end
end
