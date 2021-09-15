# frozen_string_literal: true

class AddBalanceToPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    add_column :payment_addresses, :balances, :jsonb, default: {}
    add_column :payment_addresses, :balances_updated_at, :timestamp
  end
end
