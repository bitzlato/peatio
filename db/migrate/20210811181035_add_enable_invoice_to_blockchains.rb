class AddEnableInvoiceToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :enable_invoice, :boolean, null: false, default: false
    Blockchain.where(key: 'bitzlato').update_all enable_invoice: true
  end
end
