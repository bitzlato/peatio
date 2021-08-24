class AddKindToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :kind, :string, null: false, default: :none

    add_index :transactions, :kind
    add_index :transactions, [:blockchain_id, :kind]
  end
end
