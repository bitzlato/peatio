# frozen_string_literal: true

class CreateBlockchainApprovals < ActiveRecord::Migration[5.2]
  def change
    create_table :blockchain_approvals do |t|
      t.string :currency_id, limit: 10, null: false, index: true
      t.citext :txid, null: false, index: true
      t.citext :owner_address, null: false, index: true
      t.citext :spender_address, null: false
      t.integer :block_number
      t.integer :status, default: 0, null: false
      t.json :options
      t.references :blockchain, index: false, foreign_key: true, null: false

      t.timestamps

      t.index %i[blockchain_id txid], unique: true
    end
  end
end
