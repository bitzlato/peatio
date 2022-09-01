# frozen_string_literal: true

class MoveFromBlockhainKeytoBlockchainId < ActiveRecord::Migration[5.2]
  def change
    [Currency, Wallet, WhitelistedSmartContract].each do |model|
      add_reference model.table_name, :blockchain
      remove_column model.table_name, :blockchain_key
      change_column_null model.table_name, :blockchain_id, false
    end

    add_index :whitelisted_smart_contracts, %i[blockchain_id address], unique: true
  end
end
