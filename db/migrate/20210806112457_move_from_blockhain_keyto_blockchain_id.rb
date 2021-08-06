class MoveFromBlockhainKeytoBlockchainId < ActiveRecord::Migration[5.2]
  def change
    [Wallet, WhitelistedSmartContract, Currency].each do |model|
      add_reference model.table_name, :blockchain
      model.find_each do |record|
        record.update blockchain: Blockchain.find_by_key(record.blockchain_key)
      end
      remove_column model.table_name, :blockchain_key
    end

    add_index :whitelisted_smart_contracts, [:blockchain_id, :address], unique: true
  end
end
