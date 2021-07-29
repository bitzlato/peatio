class AddCodeToCurrencies < ActiveRecord::Migration[5.2]
  def up
    add_column :currencies, :code, :string
    add_column :currencies, :blockchain_scope, :string
    Currency.find_each do |c|
      c.update code: c.id, blockchain_scope: c.blockchain.scope
    end
    change_column_null :currencies, :code, false
    add_index :currencies, [:code, :blockchain_scope], unique: true
  end

  def down
    remove_column :currencies, :code
    remove_column :currencies, :blockchain_scope
  end
end
