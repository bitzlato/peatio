class AddUniqueBlockchainIndexToTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_index :transactions, %w[currency_id txid]
    add_index :transactions, %w[blockchain_id txid txout], unique: true
  end
end
