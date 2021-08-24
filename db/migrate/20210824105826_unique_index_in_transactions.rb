class UniqueIndexInTransactions < ActiveRecord::Migration[5.2]
  def change
    remove_index :transactions, [:blockchain_id, :txid, :txout]
    add_index :transactions, [:blockchain_id, :txid, :txout], unique: true, where: 'txout is not null'

    Transaction.where(txout: nil).group(:txid).count.each do |txid, count|
      Transaction.where(txout: nil, txid: txid).limit(count-1).delete_all
    end
    add_index :transactions, [:blockchain_id, :txid], unique: true, where: 'txout is null'
  end
end
