# frozen_string_literal: true

class AddPlainSettingsToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :plain_settings, :json, after: :gateway
  end
end
