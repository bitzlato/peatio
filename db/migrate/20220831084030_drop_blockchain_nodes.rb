# frozen_string_literal: true

class DropBlockchainNodes < ActiveRecord::Migration[6.0]
  def up
    drop_table :blockchain_nodes
  end

  def down
    create_table :blockchain_nodes do |t|
      t.references :blockchain, foreign_key: true
      t.string :client, null: false
      t.string :server_encrypted, limit: 1024
      t.bigint :latest_block_number
      t.timestamp :server_touched_at
      t.boolean :is_public, null: false, default: false
      t.boolean :has_accounts, null: false, default: false
      t.boolean :use_for_withdraws, null: false, default: false
      t.timestamp :archived_at

      t.timestamps
    end
  end
end
