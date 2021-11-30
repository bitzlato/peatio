# frozen_string_literal: true

class AddUnifiedPriceAndCurrencyToSwapOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :swap_orders, :unified_price, :decimal, precision: 32, scale: 16
    add_column :swap_orders, :unified_total_amount, :decimal, precision: 32, scale: 16
    add_column :swap_orders, :unified_unit, :string, index: true
  end
end
