class RemoveDepositFromTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_column :transactions, :deposit_id
    remove_column :transactions, :deposit_spread_id
    add_column :transactions, :is_followed, :boolean, null: false, default: false
  end
end
