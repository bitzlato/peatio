class AddDepositReferencesToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :deposit_id, :bigint
    add_column :transactions, :deposit_spread_id, :bigint
  end
end
