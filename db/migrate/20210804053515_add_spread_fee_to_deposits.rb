class AddSpreadFeeToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :spread_fee, :decimal, precision: 32, scale: 16
  end
end
