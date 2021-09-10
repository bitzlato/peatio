class AddIsLockedToWithdraws < ActiveRecord::Migration[5.2]
  def change
    add_column :withdraws, :is_locked, :boolean, default: false, null: false
  end
end
