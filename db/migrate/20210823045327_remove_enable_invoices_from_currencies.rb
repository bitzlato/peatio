class RemoveEnableInvoicesFromCurrencies < ActiveRecord::Migration[5.2]
  def change
    remove_column :currencies, :enable_invoice
  end
end
