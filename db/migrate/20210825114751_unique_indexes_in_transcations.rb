class UniqueIndexesInTranscations < ActiveRecord::Migration[5.2]
  def change
    remove_index :transactions, name: :index_transactions_on_blockchain_id_and_txid_and_txout
    add_index :transactions, %i[blockchain_id txid], where: 'txout is null', unique: true
    add_index :transactions, %i[blockchain_id txid txout], where: 'txout is not null', unique: true

    Transaction.group(:txid).count.each do |txid, count|
      Transaction.where(txid: txid).limit(count - 1).delete_all
    end
    change_column_null :transactions, :txout, true
    Transaction.where(txout: 0).update_all txout: nil
  end
end
