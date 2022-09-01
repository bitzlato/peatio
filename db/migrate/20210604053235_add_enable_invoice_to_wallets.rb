# frozen_string_literal: true

class AddEnableInvoiceToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :enable_invoice, :boolean, null: false, default: false
  end
end
