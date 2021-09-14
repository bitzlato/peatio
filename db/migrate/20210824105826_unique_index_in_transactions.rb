# frozen_string_literal: true

class UniqueIndexInTransactions < ActiveRecord::Migration[5.2]
  def up
    Transaction.where(txout: nil).group(:txid).count.each do |txid, count|
      Transaction.where(txout: nil, txid: txid).limit(count - 1).delete_all
    end
    Transaction.where(txout: nil).update_all txout: 0
    change_column_null :transactions, :txout, false
  end

  def down
    change_column_null :transactions, :txout, true
  end
end
