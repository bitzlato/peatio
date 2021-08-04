class MoveFromBlockhainKeytoBlockchainId < ActiveRecord::Migration[5.2]
  def change
    [Currency, Wallet, WhitelistedSmartContract].each do |model|
      add_reference model.table_name, :blockchain
      model.find_each do |record|
        model.where(id: record.id).update_all(
          blockchain_id: Blockchain.find_by_key(record.read_attribute :blockchain_key).try(:id) ||
          raise("No blockchain #{record.blockchain_key} found")
        )
      end
      remove_column model.table_name, :blockchain_key
      change_column_null model.table_name, :blockchain_id, false
    end

    add_index :whitelisted_smart_contracts, [:blockchain_id, :address], unique: true
  end
end
