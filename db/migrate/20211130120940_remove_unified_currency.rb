class RemoveUnifiedCurrency < ActiveRecord::Migration[5.2]
  def change
    remove_column :swap_orders, :unified_unit
    remove_column :swap_orders, :unified_total_amount
    remove_column :swap_orders, :unified_price
  end
end
