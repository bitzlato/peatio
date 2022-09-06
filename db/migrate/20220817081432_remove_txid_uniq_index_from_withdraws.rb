# frozen_string_literal: true

class RemoveTxidUniqIndexFromWithdraws < ActiveRecord::Migration[6.0]
  def up
    remove_index :withdraws, %i[currency_id txid]
  end

  def down
    add_index :withdraws, %i[currency_id txid], unique: true
  end
end
