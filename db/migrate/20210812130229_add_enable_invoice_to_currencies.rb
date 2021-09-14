# frozen_string_literal: true

class AddEnableInvoiceToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :enable_invoice, :boolean, null: false, default: false
    Currency.where(id: %i[btc eth usdt mcr]).update_all enable_invoice: true
  end
end
