# frozen_string_literal: true

class DropBlockchainAddresses < ActiveRecord::Migration[6.0]
  def up
    drop_table :blockchain_addresses
  end

  def down
    create_table :blockchain_addresses do |t|
      t.string :address_type, null: false
      t.citext :address, null: false
      t.string :private_key_hex_encrypted, length: 1024, null: true, comment: 'Is must be NOT NULL but vault-rails does not support it'

      t.timestamps
    end
    add_index :blockchain_addresses, %i[address address_type], unique: true
  end
end
