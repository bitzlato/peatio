# frozen_string_literal: true

class RemoveEncryptedColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :blockchains, :server_encrypted, :string, limit: 1024
    remove_column :wallets, :settings_encrypted, :string, limit: 1024
    remove_column :payment_addresses, :secret_encrypted, :string, limit: 255
    remove_column :payment_addresses, :details_encrypted, :string, limit: 1024
  end
end
