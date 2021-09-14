class AddAccountableFeeToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :accountable_fee, :boolean, null: false, default: false

    add_reference :transactions, :blockchain, null: true
    Transaction.find_each do |t|
      t.update_columns blockchain_id: t.currency.blockchain_id
    end

    change_column_null :transactions, :blockchain_id, false
    add_index :transactions, %i[blockchain_id accountable_fee]
  end
end
