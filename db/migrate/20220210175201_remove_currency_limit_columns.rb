# frozen_string_literal: true

class RemoveCurrencyLimitColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :currencies, :withdraw_fee, :decimal, precision: 32, scale: 18, default: 0, null: false
    remove_column :currencies, :min_deposit_amount, :decimal, precision: 32, scale: 18, default: 0, null: false
  end
end
