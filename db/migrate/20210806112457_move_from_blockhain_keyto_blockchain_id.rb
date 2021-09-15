# frozen_string_literal: true

class MoveFromBlockhainKeytoBlockchainId < ActiveRecord::Migration[5.2]
  def change
    Blockchain.where(key: 'eth-mainet').update_all key: 'eth-mainnet'
    [Currency, Wallet, WhitelistedSmartContract].each do |model|
      model.where(blockchain_key: 'eth-mainet').update_all blockchain_key: 'eth-mainnet'
      add_reference model.table_name, :blockchain
      model.find_each do |record|
        model.where(id: record.id).update_all(
          blockchain_id: Blockchain.find_by_key(record.read_attribute(:blockchain_key)).try(:id) ||
          Blockchain.find_by_key('dummy').try(:id) ||
          raise("No blockchain #{record.read_attribute :blockchain_key} found in #{model} #{record.id}")
        )
      end
      remove_column model.table_name, :blockchain_key
      change_column_null model.table_name, :blockchain_id, false
    end

    add_index :whitelisted_smart_contracts, %i[blockchain_id address], unique: true
  end
end
