class CreateBlockchainNodes < ActiveRecord::Migration[5.2]
  def up
    create_table :blockchain_nodes do |t|
      t.references :blockchain, foreign_key: true
      t.string :client, null: false
      t.string :server_encrypted, null: false
      t.bigint :latest_block_number
      t.timestamp :info_updated_at
      t.boolean :is_public, null: false, default: false
      t.boolean :has_accounts, null: false, default: false
      t.boolean :use_for_withdraws, null: false, default: false
      t.timestamp :archived_at

      t.timestamps
    end

    if Rails.env.prodution?
      Blockchain.find_each do |b|
        b.nodes.create!(server: b.server, client: b.client, has_accounts: true, use_for_withdraws: true, is_public: false) if b.server.present?
      end

      b = Blockchain.find_by(key: 'heco-mainnet')
      b.nodes.create!(server: 'https://http-mainnet.hecochain.com', client: 'ethereum', has_accounts: false, is_public: true, use_for_withdraws: false) if b.present?
    end
  end

  def down
    drop_table :blockchain_nodes
  end
end
