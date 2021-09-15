# frozen_string_literal: true

class AddBlockhainToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_reference :deposits, :blockchain
    Deposit.find_each do |d|
      raise "No blockchain for currency #{d.currency.id}" if d.currency.blockchain.nil?

      Deposit.where(id: d.id).update_all blockchain_id: d.currency.blockchain.id
    end

    change_column_null :deposits, :blockchain_id, false
    add_index :deposits, %i[blockchain_id txid], unique: true, where: 'txid is not null'
  end
end
