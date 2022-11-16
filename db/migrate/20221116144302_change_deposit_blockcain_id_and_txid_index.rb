# frozen_string_literal: true

class ChangeDepositBlockcainIdAndTxidIndex < ActiveRecord::Migration[6.0]
  def up
    remove_index :deposits, %i[blockchain_id txid]
    add_index :deposits, %i[blockchain_id txid], unique: true, where: 'txid is not null and txout is null'
    add_index :deposits, %i[blockchain_id txid txout], unique: true, where: 'txid is not null and txout is not null'
  end

  def down
    remove_index :deposits, %i[blockchain_id txid txout]
    remove_index :deposits, %i[blockchain_id txid]
    add_index :deposits, %i[blockchain_id txid], unique: true, where: 'txid is not null'
  end
end
