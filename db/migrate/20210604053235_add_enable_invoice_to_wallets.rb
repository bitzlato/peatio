# frozen_string_literal: true

class AddEnableInvoiceToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :enable_invoice, :boolean, null: false, default: false
    Wallet.find_each do |w|
      next if w.settings.blank?

      w.update!(
        enable_invoice: w.settings.fetch('enable_intention', false),
        settings: w.settings.reject { |k| k == 'enable_intention' }
      )
    end
  end
end
