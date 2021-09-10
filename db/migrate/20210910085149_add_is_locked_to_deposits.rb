class AddIsLockedToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :is_locked, :boolean, default: false, null: false
  end
end
