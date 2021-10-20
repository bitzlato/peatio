# frozen_string_literal: true

class CreateBlockchainAddresses < ActiveRecord::Migration[5.2]
  def down
    drop_table :blockchain_addresses
    remove_column :blockchains, :address_type
  end

  def up
    create_table :blockchain_addresses do |t|
      t.string :address_type, null: false
      t.citext :address, null: false
      t.string :private_key_hex_encrypted, length: 1024, null: true, comment: 'Is must be NOT NULL but vault-rails does not support it'

      t.timestamps
    end

    add_column :blockchains, :address_type, :string
    add_index :blockchain_addresses, %i[address address_type], unique: true

    Blockchain.where(client: 'ethereum').update_all address_type: 'ethereum'
  end
end
