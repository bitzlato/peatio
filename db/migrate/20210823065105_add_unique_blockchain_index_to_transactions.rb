class AddUniqueBlockchainIndexToTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_index :transactions, ["currency_id", "txid"]
    add_index :transactions, ["blockchain_id", "txid", "txout"], unique: true
  end
end
