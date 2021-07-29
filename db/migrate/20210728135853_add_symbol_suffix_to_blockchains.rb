class AddSymbolSuffixToBlockchains < ActiveRecord::Migration[5.2]
  def up
    add_column :blockchains, :scope, :string
    Blockchain.find_each do |b|
      b.update scope: b.key.split('-').first
    end
    change_column_null :blockchains, :scope, false
  end

  def down
    remove_column :blockchains, :scope
  end
end
