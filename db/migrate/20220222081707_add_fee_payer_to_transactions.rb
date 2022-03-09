class AddFeePayerToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :fee_payer_address, :string
    Transaction.update_all("fee_payer_address = from_address")
  end
end
