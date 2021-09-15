# frozen_string_literal: true

class RemoveGatewayFromWallets < ActiveRecord::Migration[5.2]
  def change
    remove_column :wallets, :gateway
  end
end
