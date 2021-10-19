# frozen_string_literal: true

class CreateBlockchainAddresses < ActiveRecord::Migration[5.2]
  def change
    create_table :blockchain_addresses do |t|
      t.string :address_type, null: false
      t.string :address, null: false
      t.text :private_key_encrypted, null: false

      t.timestamps
    end

    add_column :blockchains, :address_type, :string

    Blockchain.where(client: 'ethereum').update_all address_type: 'ethereum'
  end
end
