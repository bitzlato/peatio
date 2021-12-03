# frozen_string_literal: true

class AddAdditionalColumensToSwapOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :swap_orders, :from_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :to_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :request_unit, :string, index: true # , null: false
    add_column :swap_orders, :request_volume, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :request_price, :decimal, precision: 36, scale: 18
    add_column :swap_orders, :inverse_price, :decimal, precision: 36, scale: 18

    # SwapOrder.update_all "request_unit = from_unit, from_volume = value, to_volume = value, request_volume = value, request_price=price, inverse_price=1/price"
    # remove_column :swap_orders, :volume
    # remove_column :swap_orders, :price
  end
end