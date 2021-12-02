# frozen_string_literal: true

class AddAdditionalColumensToSwapOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :swap_orders, :from_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :to_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :request_unit, :string, index: true, null: false
    add_column :swap_orders, :request_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :request_price, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :inverse_price, :decimal, precision: 36, scale: 18

    remove_column :swap_orders, :volume
    remove_column :swap_orders, :price
  end
end
