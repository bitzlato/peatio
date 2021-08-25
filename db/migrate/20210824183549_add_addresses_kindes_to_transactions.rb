class AddAddressesKindesToTransactions < ActiveRecord::Migration[5.2]
  def up
    add_column :transactions, :to, :integer
    add_column :transactions, :from, :integer
    remove_column :transactions, :kind
    add_column :transactions, :kind, :integer
  end
end
